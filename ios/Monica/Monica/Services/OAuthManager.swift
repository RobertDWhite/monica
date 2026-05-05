import AuthenticationServices
import CryptoKit
import Foundation

enum OAuthError: LocalizedError {
    case discoveryFailed
    case userCancelled
    case invalidCallback
    case tokenExchangeFailed(String)
    case monicaTokenExchangeFailed(String)

    var errorDescription: String? {
        switch self {
        case .discoveryFailed:
            return "Could not reach the OAuth provider. Check the issuer URL."
        case .userCancelled:
            return "Login was cancelled."
        case .invalidCallback:
            return "OAuth provider returned an unexpected response."
        case .tokenExchangeFailed(let msg):
            return "OAuth token exchange failed: \(msg)"
        case .monicaTokenExchangeFailed(let msg):
            return "Could not get Monica token: \(msg)"
        }
    }
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

    private struct OAuthTokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let error: String?
        let errorDescription: String?
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case error
            case errorDescription = "error_description"
        }
    }

    private struct MonicaTokenResponse: Decodable {
        let token: String?
        let error: [String: String]?
    }

    /// Full flow: OIDC PKCE → exchange Authentik access token → Monica Sanctum token.
    func loginAndGetMonicaToken(issuerURL: String, clientID: String, serverURL: String) async throws -> String {
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

        let oauthTokens = try await exchangeCode(
            code,
            verifier: verifier,
            tokenEndpoint: config.tokenEndpoint,
            clientID: clientID
        )

        return try await exchangeForMonicaToken(
            oauthAccessToken: oauthTokens.accessToken,
            serverURL: serverURL
        )
    }

    // MARK: - Private helpers

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
            objc_setAssociatedObject(self, &AssociatedKey.session, session, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private func exchangeCode(
        _ code: String,
        verifier: String,
        tokenEndpoint: String,
        clientID: String
    ) async throws -> OAuthTokenResponse {
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
        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)

        if let error = response.error {
            throw OAuthError.tokenExchangeFailed(response.errorDescription ?? error)
        }

        return response
    }

    private func exchangeForMonicaToken(oauthAccessToken: String, serverURL: String) async throws -> String {
        let base = serverURL.trimmingCharacters(in: .init(charactersIn: "/"))
        guard let url = URL(string: base + "/api/auth/token") else {
            throw OAuthError.monicaTokenExchangeFailed("Invalid server URL")
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(oauthAccessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw OAuthError.monicaTokenExchangeFailed("No HTTP response")
        }

        let parsed = try? JSONDecoder().decode(MonicaTokenResponse.self, from: data)

        guard http.statusCode == 200, let token = parsed?.token else {
            let msg = parsed?.error?.values.first ?? "HTTP \(http.statusCode)"
            throw OAuthError.monicaTokenExchangeFailed(msg)
        }

        return token
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
        DispatchQueue.main.sync {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
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
