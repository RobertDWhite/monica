import SwiftUI

@Observable
@MainActor
final class AppState {
    // Non-sensitive — UserDefaults
    var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    var oauthIssuerURL: String {
        didSet { UserDefaults.standard.set(oauthIssuerURL, forKey: "oauthIssuerURL") }
    }
    var oauthClientID: String {
        didSet { UserDefaults.standard.set(oauthClientID, forKey: "oauthClientID") }
    }

    // Sensitive — Keychain
    var apiToken: String {
        didSet { KeychainHelper.save(apiToken, for: "apiToken") }
    }

    var isConfigured: Bool {
        !serverURL.isEmpty && !apiToken.isEmpty
    }

    var isOAuthConfigured: Bool {
        !oauthIssuerURL.isEmpty && !oauthClientID.isEmpty
    }

    init() {
        serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        oauthIssuerURL = UserDefaults.standard.string(forKey: "oauthIssuerURL") ?? ""
        oauthClientID = UserDefaults.standard.string(forKey: "oauthClientID") ?? ""
        apiToken = KeychainHelper.load("apiToken") ?? ""
    }

    func signOut() {
        serverURL = ""
        apiToken = ""
        oauthIssuerURL = ""
        oauthClientID = ""
        KeychainHelper.delete("apiToken")
    }
}
