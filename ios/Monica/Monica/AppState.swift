import SwiftUI

enum AuthMethod: String {
    case apiToken = "apiToken"
    case oauth = "oauth"
}

@Observable
@MainActor
final class AppState {
    // MARK: - Persisted (UserDefaults — non-sensitive)
    var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    var authMethod: AuthMethod {
        didSet { UserDefaults.standard.set(authMethod.rawValue, forKey: "authMethod") }
    }
    var oauthIssuerURL: String {
        didSet { UserDefaults.standard.set(oauthIssuerURL, forKey: "oauthIssuerURL") }
    }
    var oauthClientID: String {
        didSet { UserDefaults.standard.set(oauthClientID, forKey: "oauthClientID") }
    }
    var oauthTokenExpiry: Date? {
        didSet {
            if let expiry = oauthTokenExpiry {
                UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: "oauthTokenExpiry")
            } else {
                UserDefaults.standard.removeObject(forKey: "oauthTokenExpiry")
            }
        }
    }

    // MARK: - Persisted (Keychain — sensitive)
    var apiToken: String {
        didSet { KeychainHelper.save(apiToken, for: "apiToken") }
    }
    var oauthAccessToken: String {
        didSet { KeychainHelper.save(oauthAccessToken, for: "oauthAccessToken") }
    }
    var oauthRefreshToken: String {
        didSet { KeychainHelper.save(oauthRefreshToken, for: "oauthRefreshToken") }
    }

    // MARK: - Computed

    var isConfigured: Bool {
        guard !serverURL.isEmpty else { return false }
        switch authMethod {
        case .apiToken: return !apiToken.isEmpty
        case .oauth: return !oauthAccessToken.isEmpty
        }
    }

    var bearerToken: String {
        switch authMethod {
        case .apiToken: return apiToken
        case .oauth: return oauthAccessToken
        }
    }

    var oauthTokenIsExpired: Bool {
        guard authMethod == .oauth, let expiry = oauthTokenExpiry else { return false }
        return Date() >= expiry.addingTimeInterval(-30)
    }

    // MARK: - Init

    init() {
        serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        authMethod = AuthMethod(rawValue: UserDefaults.standard.string(forKey: "authMethod") ?? "") ?? .apiToken
        oauthIssuerURL = UserDefaults.standard.string(forKey: "oauthIssuerURL") ?? ""
        oauthClientID = UserDefaults.standard.string(forKey: "oauthClientID") ?? ""
        let expiryTs = UserDefaults.standard.double(forKey: "oauthTokenExpiry")
        oauthTokenExpiry = expiryTs > 0 ? Date(timeIntervalSince1970: expiryTs) : nil

        apiToken = KeychainHelper.load("apiToken") ?? ""
        oauthAccessToken = KeychainHelper.load("oauthAccessToken") ?? ""
        oauthRefreshToken = KeychainHelper.load("oauthRefreshToken") ?? ""
    }

    // MARK: - Actions

    func applyOAuthTokens(_ tokens: OAuthTokens) {
        oauthAccessToken = tokens.accessToken
        oauthRefreshToken = tokens.refreshToken ?? ""
        if let expiresIn = tokens.expiresIn {
            oauthTokenExpiry = Date().addingTimeInterval(TimeInterval(expiresIn))
        }
    }

    /// Returns true if refresh succeeded, false if the user must re-authenticate.
    func refreshOAuthTokenIfNeeded() async -> Bool {
        guard authMethod == .oauth, oauthTokenIsExpired, !oauthRefreshToken.isEmpty else {
            return true
        }
        do {
            let tokens = try await OAuthManager().refresh(
                refreshToken: oauthRefreshToken,
                issuerURL: oauthIssuerURL,
                clientID: oauthClientID
            )
            applyOAuthTokens(tokens)
            return true
        } catch {
            return false
        }
    }

    func signOut() {
        serverURL = ""
        apiToken = ""
        oauthAccessToken = ""
        oauthRefreshToken = ""
        oauthTokenExpiry = nil
        oauthIssuerURL = ""
        oauthClientID = ""
        authMethod = .apiToken
        KeychainHelper.delete("apiToken")
        KeychainHelper.delete("oauthAccessToken")
        KeychainHelper.delete("oauthRefreshToken")
    }
}
