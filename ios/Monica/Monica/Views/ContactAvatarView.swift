import SwiftUI
import UIKit
import CryptoKit

/// Circular contact avatar used in lists and headers.
///
/// Photo avatars come back from the API as absolute URLs baked with the
/// server's `APP_URL`, which can point at a different (auth-gated) host than
/// the one the app actually talks to. We re-root the URL onto the configured
/// server origin, download the bytes with the app's bearer token, and cache
/// them on disk so we render from a local copy instead of hotlinking the
/// deployment on every appearance.
struct ContactAvatarView: View {
    let avatar: ContactAvatar?
    let size: CGFloat

    var body: some View {
        CachedAvatarImage(avatar: avatar)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

/// Renders a photo avatar from the local cache, falling back to a placeholder
/// while loading or when there is no photo. Fills its container; callers apply
/// any frame and clipping.
struct CachedAvatarImage: View {
    @Environment(AppState.self) private var appState
    let avatar: ContactAvatar?

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                placeholder
            }
        }
        .task(id: resolvedURL) { await load() }
    }

    private var resolvedURL: URL? {
        guard let avatar, avatar.type == "url" else { return nil }
        return AvatarImageStore.reroot(avatar.content, onto: appState.serverURL)
    }

    @MainActor
    private func load() async {
        image = nil
        guard let url = resolvedURL else { return }
        // Only forward the bearer token to our own server origin, never to a
        // host baked into a stale/legacy avatar URL.
        let serverHost = URLComponents(string: appState.serverURL.trimmingCharacters(in: .init(charactersIn: "/")))?.host
        let token = url.host == serverHost ? appState.apiToken : ""
        image = try? await AvatarImageStore.shared.image(for: url, token: token)
    }

    private var placeholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundStyle(.secondary)
    }
}

/// In-memory + on-disk cache for downloaded avatar images.
final class AvatarImageStore: @unchecked Sendable {
    static let shared = AvatarImageStore()

    private let memory = NSCache<NSURL, UIImage>()
    private let directory: URL

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        directory = caches.appendingPathComponent("ContactAvatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Re-root a stored absolute URL onto the configured server origin so the
    /// image is fetched from the same host the app uses for the API.
    static func reroot(_ content: String, onto serverURL: String) -> URL? {
        guard let stored = URLComponents(string: content) else { return nil }
        let trimmed = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var server = URLComponents(string: trimmed), server.host != nil else {
            return URL(string: content)
        }
        server.path = stored.path
        server.query = stored.query
        server.fragment = stored.fragment
        return server.url
    }

    func image(for url: URL, token: String) async throws -> UIImage {
        if let hit = memory.object(forKey: url as NSURL) { return hit }

        let fileURL = directory.appendingPathComponent(Self.filename(for: url))
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            memory.setObject(image, forKey: url as NSURL)
            return image
        }

        var request = URLRequest(url: url)
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        try? data.write(to: fileURL, options: .atomic)
        memory.setObject(image, forKey: url as NSURL)
        return image
    }

    private static func filename(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
