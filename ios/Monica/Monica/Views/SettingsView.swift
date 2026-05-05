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

                if appState.isOAuthConfigured {
                    Section("OAuth") {
                        LabeledContent("Issuer", value: appState.oauthIssuerURL)
                        LabeledContent("Client ID", value: appState.oauthClientID)
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
