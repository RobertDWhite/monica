import SwiftUI

@Observable
final class AppState {
    var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    var apiToken: String {
        didSet { UserDefaults.standard.set(apiToken, forKey: "apiToken") }
    }

    var isConfigured: Bool {
        !serverURL.isEmpty && !apiToken.isEmpty
    }

    init() {
        serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        apiToken = UserDefaults.standard.string(forKey: "apiToken") ?? ""
    }

    func signOut() {
        serverURL = ""
        apiToken = ""
    }
}
