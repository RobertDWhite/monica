import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var serverURL = ""
    @State private var selectedMethod: AuthMethod = .apiToken

    // API token fields
    @State private var apiToken = ""

    // OAuth fields
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

                Section("Monica Server") {
                    TextField("https://monica.example.com", text: $serverURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Authentication Method") {
                    Picker("Method", selection: $selectedMethod) {
                        Text("API Token").tag(AuthMethod.apiToken)
                        Text("OAuth / SSO").tag(AuthMethod.oauth)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                switch selectedMethod {
                case .apiToken:
                    apiTokenSection
                case .oauth:
                    oauthSection
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
                                Text(selectedMethod == .oauth ? "Opening browser…" : "Connecting…")
                            }
                        } else {
                            Text(selectedMethod == .oauth ? "Sign In with OAuth" : "Connect")
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
    private var apiTokenSection: some View {
        Section("API Token") {
            SecureField("Paste your token here", text: $apiToken)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !serverURL.isEmpty, let tokenURL = URL(string: serverURL.trimmingCharacters(in: .init(charactersIn: "/")) + "/tokens") {
                Link("Generate a token in Monica → Settings → API Tokens",
                     destination: tokenURL)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var oauthSection: some View {
        Section("OAuth / OIDC Provider") {
            TextField("https://auth.example.com/application/o/monica", text: $oauthIssuerURL)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            TextField("Client ID", text: $oauthClientID)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }

        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("Authentik setup", systemImage: "info.circle")
                    .font(.subheadline.bold())
                Text("In Authentik, create an OAuth2/OIDC provider with:\n• Redirect URI: **monica://oauth/callback**\n• Grant type: Authorization Code\n• PKCE: enabled\n\nThe issuer URL is your provider's base URL (e.g. the URL shown in Authentik under the provider's OpenID Configuration).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
        }
    }

    private var canConnect: Bool {
        guard !serverURL.isEmpty else { return false }
        switch selectedMethod {
        case .apiToken: return !apiToken.isEmpty
        case .oauth: return !oauthIssuerURL.isEmpty && !oauthClientID.isEmpty
        }
    }

    private func connect() async {
        isConnecting = true
        errorMessage = nil

        switch selectedMethod {
        case .apiToken:
            await connectWithToken()
        case .oauth:
            await connectWithOAuth()
        }

        isConnecting = false
    }

    private func connectWithToken() async {
        let api = MonicaAPI(baseURL: serverURL, token: apiToken)
        do {
            _ = try await api.vaults()
            appState.serverURL = serverURL
            appState.apiToken = apiToken
            appState.authMethod = .apiToken
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func connectWithOAuth() async {
        do {
            let tokens = try await oauthManager.authorize(
                issuerURL: oauthIssuerURL,
                clientID: oauthClientID
            )
            // Validate the token works against Monica before saving
            let api = MonicaAPI(baseURL: serverURL, token: tokens.accessToken)
            _ = try await api.vaults()

            appState.serverURL = serverURL
            appState.oauthIssuerURL = oauthIssuerURL
            appState.oauthClientID = oauthClientID
            appState.authMethod = .oauth
            appState.applyOAuthTokens(tokens)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
