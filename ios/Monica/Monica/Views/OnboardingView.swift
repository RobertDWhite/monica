import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var serverURL = ""
    @State private var useOAuth = false

    // Direct token
    @State private var apiToken = ""

    // OAuth
    @State private var oauthIssuerURL = ""
    @State private var oauthClientID = ""

    @State private var isConnecting = false
    @State private var errorMessage: String?

    private let oauthManager = OAuthManager()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monica Personal CRM")
                            .font(.title2.bold())
                        Text("Connect to your self-hosted Monica server.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 8)
                }

                Section("Monica Server URL") {
                    TextField("https://monica.example.com", text: $serverURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Toggle("Behind Authentik or another OAuth provider", isOn: $useOAuth)
                }

                if useOAuth {
                    oauthSection
                } else {
                    tokenSection
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await connect() }
                    } label: {
                        if isConnecting {
                            HStack {
                                ProgressView()
                                Text(useOAuth ? "Signing in…" : "Connecting…")
                            }
                        } else {
                            Text(useOAuth ? "Sign In via OAuth" : "Connect")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!canConnect || isConnecting)
                }
            }
            .navigationTitle("Setup")
        }
    }

    @ViewBuilder
    private var tokenSection: some View {
        Section("API Token") {
            SecureField("Paste your API token", text: $apiToken)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !serverURL.isEmpty,
               let url = URL(string: serverURL.trimmingCharacters(in: .init(charactersIn: "/")) + "/tokens") {
                Link("Open Monica → Settings → API Tokens", destination: url)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var oauthSection: some View {
        Section("OAuth / OIDC Provider") {
            TextField("Issuer URL", text: $oauthIssuerURL)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            TextField("Client ID", text: $oauthClientID)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }

        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("The app will sign you in through your provider, then automatically generate a Monica API token. Your provider must set `OIDC_ISSUER` on the Monica server.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Authentik: use the application's OpenID Configuration issuer URL. Set the redirect URI to **monica://oauth/callback** and enable PKCE.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
        }
    }

    private var canConnect: Bool {
        guard !serverURL.isEmpty else { return false }
        if useOAuth {
            return !oauthIssuerURL.isEmpty && !oauthClientID.isEmpty
        }
        return !apiToken.isEmpty
    }

    private func connect() async {
        isConnecting = true
        errorMessage = nil

        if useOAuth {
            await connectViaOAuth()
        } else {
            await connectWithToken()
        }

        isConnecting = false
    }

    private func connectWithToken() async {
        let api = MonicaAPI(baseURL: serverURL, token: apiToken)
        do {
            _ = try await api.vaults()
            appState.serverURL = serverURL
            appState.apiToken = apiToken
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func connectViaOAuth() async {
        do {
            let monicaToken = try await oauthManager.loginAndGetMonicaToken(
                issuerURL: oauthIssuerURL,
                clientID: oauthClientID,
                serverURL: serverURL
            )
            // Verify it works
            let api = MonicaAPI(baseURL: serverURL, token: monicaToken)
            _ = try await api.vaults()

            appState.serverURL = serverURL
            appState.apiToken = monicaToken
            appState.oauthIssuerURL = oauthIssuerURL
            appState.oauthClientID = oauthClientID
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
