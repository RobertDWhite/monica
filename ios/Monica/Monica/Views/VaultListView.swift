import SwiftUI

struct VaultListView: View {
    @Environment(AppState.self) private var appState

    @State private var vaults: [Vault] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSettings = false
    @State private var showCreate = false
    @State private var editingVault: Vault?
    @State private var deleteTarget: Vault?

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
                    ContentUnavailableView {
                        Label("No Vaults", systemImage: "archivebox")
                    } actions: {
                        Button("Create Vault") { showCreate = true }
                    }
                } else {
                    List {
                        ForEach(vaults) { vault in
                            NavigationLink(value: vault) {
                                VStack(alignment: .leading) {
                                    Text(vault.name).font(.headline)
                                    if let description = vault.description, !description.isEmpty {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { deleteTarget = vault } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { editingVault = vault } label: {
                                    Label("Edit", systemImage: "pencil")
                                }.tint(.blue)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gear") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showCreate) {
                AddEditVaultView(existing: nil) { _ in Task { await load() } }
            }
            .sheet(item: $editingVault) { vault in
                AddEditVaultView(existing: vault) { _ in Task { await load() } }
            }
            .confirmationDialog(
                "Delete \(deleteTarget?.name ?? "vault")?",
                isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let t = deleteTarget { Task { await delete(t) } }
                }
            } message: {
                Text("This permanently deletes the vault and all its contacts.")
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            vaults = try await api.vaults()
        } catch APIError.unauthorized {
            appState.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func delete(_ vault: Vault) async {
        do { try await api.deleteVault(vaultId: vault.id); await load() }
        catch { errorMessage = error.localizedDescription }
        deleteTarget = nil
    }
}

struct AddEditVaultView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let existing: Vault?
    let onSaved: (Vault) -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                    }
                }
                Section("Vault") {
                    TextField("Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(existing == nil ? "New Vault" : "Edit Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                        .overlay { if isSaving { ProgressView().scaleEffect(0.7) } }
                }
            }
            .onAppear {
                name = existing?.name ?? ""
                description = existing?.description ?? ""
            }
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = VaultPayload(name: name, description: description.isEmpty ? nil : description)
        do {
            let saved: Vault
            if let existing {
                saved = try await api.updateVault(vaultId: existing.id, payload: payload)
            } else {
                saved = try await api.createVault(payload: payload)
            }
            onSaved(saved); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
