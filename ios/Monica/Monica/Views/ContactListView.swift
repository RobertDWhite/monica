import SwiftUI

struct ContactListView: View {
    @Environment(AppState.self) private var appState
    let vault: Vault

    @State private var contacts: [Contact] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var showAddContact = false

    private var api: MonicaAPI {
        MonicaAPI(baseURL: appState.serverURL, token: appState.bearerToken)
    }

    private var filtered: [Contact] {
        guard !searchText.isEmpty else { return contacts }
        return contacts.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if isLoading && contacts.isEmpty {
                ProgressView("Loading contacts…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage, contacts.isEmpty {
                ContentUnavailableView {
                    Label("Could Not Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Retry") { Task { await load() } }
                }
            } else if contacts.isEmpty {
                ContentUnavailableView("No Contacts", systemImage: "person.2")
            } else if filtered.isEmpty {
                ContentUnavailableView.search
            } else {
                List(filtered) { contact in
                    NavigationLink(value: contact) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(contact.displayName)
                                    .font(.headline)
                                if let nickname = contact.nickname, !nickname.isEmpty {
                                    Text("\"\(nickname)\"")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .refreshable { await load() }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
        .navigationTitle(vault.name)
        .navigationDestination(for: Contact.self) { contact in
            ContactDetailView(vault: vault, contact: contact)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddContact = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddEditContactView(vault: vault) { newContact in
                contacts.append(newContact)
                contacts.sort { $0.displayName < $1.displayName }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            contacts = try await api.contacts(vaultId: vault.id)
            contacts.sort { $0.displayName < $1.displayName }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
