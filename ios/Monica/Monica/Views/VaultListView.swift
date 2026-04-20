import SwiftUI

struct VaultListView: View {
    @Environment(AppState.self) private var appState

    @State private var vaults: [Vault] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var api: MonicaAPI {
        MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && vaults.isEmpty {
                    ProgressView("Loading vaults…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage, vaults.isEmpty {
                    ContentUnavailableView {
                        Label("Could Not Load", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Retry") { Task { await load() } }
                    }
                } else if vaults.isEmpty {
                    ContentUnavailableView("No Vaults", systemImage: "archivebox")
                } else {
                    List(vaults) { vault in
                        NavigationLink(value: vault) {
                            VStack(alignment: .leading) {
                                Text(vault.name)
                                    .font(.headline)
                                if let description = vault.description, !description.isEmpty {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Vaults")
            .navigationDestination(for: Vault.self) { vault in
                ContactListView(vault: vault)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out", role: .destructive) {
                        appState.signOut()
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            vaults = try await api.vaults()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
