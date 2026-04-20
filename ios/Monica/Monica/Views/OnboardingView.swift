import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var serverURL = ""
    @State private var apiToken = ""
    @State private var isValidating = false
    @State private var errorMessage: String?

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

                Section("Server") {
                    TextField("https://monica.example.com", text: $serverURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("API Token") {
                    SecureField("Paste your token here", text: $apiToken)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Link("Generate a token in Monica → Settings → API Tokens",
                         destination: URL(string: serverURL.isEmpty ? "https://example.com" : serverURL + "/tokens")!)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                        if isValidating {
                            HStack {
                                ProgressView()
                                Text("Connecting…")
                            }
                        } else {
                            Text("Connect")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(serverURL.isEmpty || apiToken.isEmpty || isValidating)
                }
            }
            .navigationTitle("Setup")
        }
    }

    private func connect() async {
        isValidating = true
        errorMessage = nil
        let api = MonicaAPI(baseURL: serverURL, token: apiToken)
        do {
            _ = try await api.vaults()
            appState.serverURL = serverURL
            appState.apiToken = apiToken
        } catch {
            errorMessage = error.localizedDescription
        }
        isValidating = false
    }
}
