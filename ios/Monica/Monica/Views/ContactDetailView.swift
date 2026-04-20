import SwiftUI

struct ContactDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact

    @State private var showEditContact = false
    @State private var currentContact: Contact
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false

    init(vault: Vault, contact: Contact) {
        self.vault = vault
        self.contact = contact
        _currentContact = State(initialValue: contact)
    }

    private var api: MonicaAPI {
        MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken)
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.secondary)
                        Text(currentContact.displayName)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        if let nickname = currentContact.nickname, !nickname.isEmpty {
                            Text("\"\(nickname)\"")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Name Details") {
                if let prefix = currentContact.prefix, !prefix.isEmpty {
                    LabeledContent("Prefix", value: prefix)
                }
                if let first = currentContact.firstName, !first.isEmpty {
                    LabeledContent("First Name", value: first)
                }
                if let middle = currentContact.middleName, !middle.isEmpty {
                    LabeledContent("Middle Name", value: middle)
                }
                if let last = currentContact.lastName, !last.isEmpty {
                    LabeledContent("Last Name", value: last)
                }
                if let maiden = currentContact.maidenName, !maiden.isEmpty {
                    LabeledContent("Maiden Name", value: maiden)
                }
                if let suffix = currentContact.suffix, !suffix.isEmpty {
                    LabeledContent("Suffix", value: suffix)
                }
            }

            if currentContact.canBeDeleted {
                Section {
                    Button("Delete Contact", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle(currentContact.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEditContact = true }
            }
        }
        .sheet(isPresented: $showEditContact) {
            AddEditContactView(vault: vault, contact: currentContact) { updated in
                currentContact = updated
            }
        }
        .confirmationDialog(
            "Delete \(currentContact.displayName)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await deleteContact() }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func deleteContact() async {
        isDeleting = true
        do {
            try await api.deleteContact(vaultId: vault.id, contactId: currentContact.id)
            dismiss()
        } catch {
            // contact delete failed — stay on screen, let user retry
        }
        isDeleting = false
    }
}
