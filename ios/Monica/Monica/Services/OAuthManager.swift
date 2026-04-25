import AuthenticationServices
import CryptoKit
import Foundation

enum OAuthError: LocalizedError {
    case discoveryFailed
    case userCancelled
    case invalidCallback
    case tokenExchangeFailed(String)
    case refreshFailed

    var errorDescription: String? {
        switch self {
        case .discoveryFailed: return "Could not reach the OAuth provider. Check the issuer URL."
        case .userCancelled: return "Login was cancelled."
        case .invalidCallback: return "OAuth provider returned an unexpected response."
        case .tokenExchangeFailed(let msg): return "Token exchange failed: \(msg)"
        case .refreshFailed: return "Session expired. Please sign in again."
        }
    }
}

struct OAuthTokens {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
}

@MainActor
final class OAuthManager: NSObject {
    static let redirectScheme = "monica"
    static let redirectURI = "monica://oauth/callback"

    private struct OIDCConfig: Decodable {
        let authorizationEndpoint: String
        let tokenEndpoint: String
        enum CodingKeys: String, CodingKey {
            case authorizationEndpoint = "authorization_endpoint"
            case tokenEndpoint = "token_endpoint"
        }
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?
        let error: String?
        let errorDescription: String?
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case error
            case errorDescription = "error_description"
        }
    }

    func authorize(issuerURL: String, clientID: String) async throws -> OAuthTokens {
        let config = try await discover(issuerURL: issuerURL)
        let (verifier, challenge) = makePKCE()
        let state = UUID().uuidString

        var comps = URLComponents(string: config.authorizationEndpoint)!
        comps.queryItems = [
            .init(name: "response_type", value: "code"),
            .init(name: "client_id", value: clientID),
            .init(name: "redirect_uri", value: Self.redirectURI),
            .init(name: "scope", value: "openid profile email offline_access"),
            .init(name: "state", value: state),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]

        let callbackURL = try await openBrowser(url: comps.url!)
        guard let callbackComps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = callbackComps.queryItems?.first(where: { $0.name == "code" })?.value
        else { throw OAuthError.invalidCallback }

        return try await exchangeCode(
            code,
            verifier: verifier,
            tokenEndpoint: config.tokenEndpoint,
            clientID: clientID
        )
    }

    func refresh(refreshToken: String, issuerURL: String, clientID: String) async throws -> OAuthTokens {
        let config = try await discover(issuerURL: issuerURL)
        var req = URLRequest(url: URL(string: config.tokenEndpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = formEncode([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID,
        ])

        let (data, _) = try await URLSession.shared.data(for: req)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        if let error = tokenResponse.error {
            throw OAuthError.tokenExchangeFailed(tokenResponse.errorDescription ?? error)
        }
        guard !tokenResponse.accessToken.isEmpty else { throw OAuthError.refreshFailed }

        return OAuthTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: tokenResponse.expiresIn
        )
    }

    // MARK: - Helpers

    private func discover(issuerURL: String) async throws -> OIDCConfig {
        let trimmed = issuerURL.trimmingCharacters(in: .init(charactersIn: "/"))
        guard let url = URL(string: trimmed + "/.well-known/openid-configuration") else {
            throw OAuthError.discoveryFailed
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try JSONDecoder().decode(OIDCConfig.self, from: data)
        } catch {
            throw OAuthError.discoveryFailed
        }
    }

    private func makePKCE() -> (verifier: String, challenge: String) {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let verifier = Data(bytes).base64URLEncoded()
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded()
        return (verifier, challenge)
    }

    private func openBrowser(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: Self.redirectScheme
            ) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: OAuthError.userCancelled)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: OAuthError.invalidCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            session.start()
            // Keep a strong reference for the duration of the session
            objc_setAssociatedObject(self, &AssociatedKey.session, session, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private func exchangeCode(
        _ code: String,
        verifier: String,
        tokenEndpoint: String,
        clientID: String
    ) async throws -> OAuthTokens {
        var req = URLRequest(url: URL(string: tokenEndpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = formEncode([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Self.redirectURI,
            "client_id": clientID,
            "code_verifier": verifier,
        ])

        let (data, _) = try await URLSession.shared.data(for: req)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        if let error = tokenResponse.error {
            throw OAuthError.tokenExchangeFailed(tokenResponse.errorDescription ?? error)
        }

        return OAuthTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: tokenResponse.expiresIn
        )
    }

    private func formEncode(_ params: [String: String]) -> Data {
        let encoded = params.map { k, v in
            let ek = k.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? k
            let ev = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? v
            return "\(ek)=\(ev)"
        }.joined(separator: "&")
        return Data(encoded.utf8)
    }
}

extension OAuthManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

private enum AssociatedKey {
    static var session = 0
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
