import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    LabeledContent("URL", value: appState.serverURL)
                }

                Section("Authentication") {
                    LabeledContent("Method") {
                        Text(appState.authMethod == .oauth ? "OAuth / SSO" : "API Token")
                            .foregroundStyle(.secondary)
                    }
                    if appState.authMethod == .oauth {
                        LabeledContent("Issuer", value: appState.oauthIssuerURL)
                        LabeledContent("Client ID", value: appState.oauthClientID)
                        if let expiry = appState.oauthTokenExpiry {
                            LabeledContent("Token expires") {
                                Text(expiry, style: .relative)
                                    .foregroundStyle(appState.oauthTokenIsExpired ? .red : .secondary)
                            }
                        }
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        showSignOutConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                    dismiss()
                }
            } message: {
                Text("You will need to reconnect to your Monica server.")
            }
        }
    }
}
