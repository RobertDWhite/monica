import SwiftUI

struct AddEditContactView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact?
    let onSave: (Contact) -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var middleName = ""
    @State private var maidenName = ""
    @State private var nickname = ""
    @State private var prefix = ""
    @State private var suffix = ""
    @State private var listed = true
    @State private var genderId: Int?
    @State private var pronounId: Int?
    @State private var reference: ReferenceData?
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(vault: Vault, contact: Contact? = nil, onSave: @escaping (Contact) -> Void) {
        self.vault = vault
        self.contact = contact
        self.onSave = onSave
    }

    private var api: MonicaAPI {
        MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken)
    }

    private var isEditing: Bool { contact != nil }

    private var canSave: Bool {
        !firstName.isEmpty || !lastName.isEmpty || !nickname.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                Section("Name") {
                    TextField("Prefix", text: $prefix)
                    TextField("First name", text: $firstName)
                    TextField("Middle name", text: $middleName)
                    TextField("Last name", text: $lastName)
                    TextField("Maiden name", text: $maidenName)
                    TextField("Suffix", text: $suffix)
                }

                Section("Identity") {
                    Picker("Gender", selection: $genderId) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(reference?.genders ?? []) { g in
                            Text(g.displayName).tag(Optional(g.id))
                        }
                    }
                    Picker("Pronoun", selection: $pronounId) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(reference?.pronouns ?? []) { p in
                            Text(p.displayName).tag(Optional(p.id))
                        }
                    }
                }

                Section("Other") {
                    TextField("Nickname", text: $nickname)
                    Toggle("Show in contact list", isOn: $listed)
                }
            }
            .navigationTitle(isEditing ? "Edit Contact" : "New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!canSave || isSaving)
                    .overlay {
                        if isSaving { ProgressView().scaleEffect(0.7) }
                    }
                }
            }
            .task { reference = try? await api.reference(vaultId: vault.id) }
            .onAppear {
                if let contact {
                    firstName = contact.firstName ?? ""
                    lastName = contact.lastName ?? ""
                    middleName = contact.middleName ?? ""
                    maidenName = contact.maidenName ?? ""
                    nickname = contact.nickname ?? ""
                    prefix = contact.prefix ?? ""
                    suffix = contact.suffix ?? ""
                    listed = contact.listed
                    genderId = contact.genderId
                    pronounId = contact.pronounId
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let payload = ContactPayload(
            firstName: firstName,
            lastName: lastName,
            middleName: middleName,
            nickname: nickname,
            maidenName: maidenName,
            prefix: prefix,
            suffix: suffix,
            listed: listed,
            genderId: genderId,
            pronounId: pronounId
        )
        do {
            let saved: Contact
            if let contact {
                saved = try await api.updateContact(vaultId: vault.id, contactId: contact.id, payload: payload)
            } else {
                saved = try await api.createContact(vaultId: vault.id, payload: payload)
            }
            onSave(saved)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
