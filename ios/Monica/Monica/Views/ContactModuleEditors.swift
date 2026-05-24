import SwiftUI

// MARK: - Shared helpers

/// API date format used by the call / important-date / reminder services.
private let apiDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private func date(day: Int?, month: Int?, year: Int?) -> Date? {
    guard let day, let month else { return nil }
    var comps = DateComponents()
    comps.day = day
    comps.month = month
    comps.year = year ?? Calendar.current.component(.year, from: Date())
    return Calendar.current.date(from: comps)
}

/// A modal scaffold shared by every module editor: navigation chrome, an
/// inline error row, and a Save button wired to an async action.
private struct EditorScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let canSave: Bool
    @Binding var errorMessage: String?
    @Binding var isSaving: Bool
    let onSave: () async -> Void
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
                content
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await onSave() } }
                        .disabled(!canSave || isSaving)
                        .overlay { if isSaving { ProgressView().scaleEffect(0.7) } }
                }
            }
        }
    }
}

// MARK: - Note

struct NoteEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactNote?
    let onSaved: (Contact) -> Void

    @State private var title = ""
    @State private var noteBody = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Note" : "Edit Note",
            canSave: !noteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Title") { TextField("Optional title", text: $title) }
            Section("Note") {
                TextField("Write something…", text: $noteBody, axis: .vertical)
                    .lineLimit(4...12)
            }
        }
        .onAppear {
            title = existing?.title ?? ""
            noteBody = existing?.body ?? ""
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = NotePayload(
            title: title.isEmpty ? nil : title,
            body: noteBody,
            emotionId: nil
        )
        do {
            let updated: Contact
            if let existing {
                updated = try await api.updateNote(vaultId: vault.id, contactId: contact.id, noteId: existing.id, payload: payload)
            } else {
                updated = try await api.createNote(vaultId: vault.id, contactId: contact.id, payload: payload)
            }
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Task

struct TaskEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactTask?
    let onSaved: (Contact) -> Void

    @State private var label = ""
    @State private var description = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Task" : "Edit Task",
            canSave: !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Task") {
                TextField("What needs doing?", text: $label)
                TextField("Notes (optional)", text: $description, axis: .vertical)
                    .lineLimit(2...6)
            }
            Section {
                Toggle("Due date", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                }
            }
        }
        .onAppear {
            label = existing?.label ?? ""
            description = existing?.description ?? ""
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = TaskPayload(
            label: label,
            description: description.isEmpty ? nil : description,
            dueAt: hasDueDate ? apiDateFormatter.string(from: dueDate) : nil
        )
        do {
            let updated: Contact
            if let existing {
                updated = try await api.updateTask(vaultId: vault.id, contactId: contact.id, taskId: existing.id, payload: payload)
            } else {
                updated = try await api.createTask(vaultId: vault.id, contactId: contact.id, payload: payload)
            }
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Call

struct CallEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactCall?
    let onSaved: (Contact) -> Void

    @State private var calledAt = Date()
    @State private var type = "audio"
    @State private var whoInitiated = "me"
    @State private var answered = true
    @State private var hasDuration = false
    @State private var duration = 5
    @State private var description = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "Log a Call" : "Edit Call",
            canSave: true,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section {
                DatePicker("When", selection: $calledAt, displayedComponents: .date)
                Picker("Type", selection: $type) {
                    Text("Audio").tag("audio")
                    Text("Video").tag("video")
                }
                Picker("Initiated by", selection: $whoInitiated) {
                    Text("Me").tag("me")
                    Text(contact.displayName).tag("contact")
                }
                Toggle("Answered", isOn: $answered)
            }
            Section {
                Toggle("Track duration", isOn: $hasDuration)
                if hasDuration {
                    Stepper("\(duration) min", value: $duration, in: 1...600)
                }
            }
            if existing == nil {
                Section("Notes") {
                    TextField("What did you talk about?", text: $description, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
        }
        .onAppear {
            if let existing {
                if let s = existing.calledAt, let d = ISO8601DateFormatter().date(from: s) { calledAt = d }
                type = existing.type ?? "audio"
                whoInitiated = existing.whoInitiated ?? "me"
                answered = existing.answered ?? true
                if let dur = existing.duration, dur > 0 { hasDuration = true; duration = dur }
                description = existing.description ?? ""
            }
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = CallPayload(
            calledAt: apiDateFormatter.string(from: calledAt),
            type: type,
            whoInitiated: whoInitiated,
            duration: hasDuration ? duration : nil,
            description: (existing == nil && !description.isEmpty) ? description : nil,
            answered: answered
        )
        do {
            let updated: Contact
            if let existing {
                updated = try await api.updateCall(vaultId: vault.id, contactId: contact.id, callId: existing.id, payload: payload)
            } else {
                updated = try await api.createCall(vaultId: vault.id, contactId: contact.id, payload: payload)
            }
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Important date

struct ImportantDateEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactDate?
    let onSaved: (Contact) -> Void

    @State private var label = ""
    @State private var day = Date()
    @State private var includeYear = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Date" : "Edit Date",
            canSave: !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Label") { TextField("Birthday, anniversary…", text: $label) }
            Section {
                DatePicker("Date", selection: $day, displayedComponents: .date)
                Toggle("Include year", isOn: $includeYear)
            }
        }
        .onAppear {
            label = existing?.label ?? ""
            if let d = date(day: existing?.day, month: existing?.month, year: existing?.year) { day = d }
            includeYear = existing?.year != nil
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: day)
        let payload = ImportantDatePayload(
            label: label,
            day: comps.day,
            month: comps.month,
            year: includeYear ? comps.year : nil
        )
        do {
            let updated: Contact
            if let existing {
                updated = try await api.updateImportantDate(vaultId: vault.id, contactId: contact.id, dateId: existing.id, payload: payload)
            } else {
                updated = try await api.createImportantDate(vaultId: vault.id, contactId: contact.id, payload: payload)
            }
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Reminder

struct ReminderEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactReminder?
    let onSaved: (Contact) -> Void

    @State private var label = ""
    @State private var date = Date()
    @State private var type = "one_time"
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Reminder" : "Edit Reminder",
            canSave: !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Reminder") { TextField("Remind me to…", text: $label) }
            Section {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Repeat", selection: $type) {
                    Text("One time").tag("one_time")
                    Text("Every year").tag("recurring_year")
                    Text("Every month").tag("recurring_month")
                    Text("Every day").tag("recurring_day")
                }
            }
        }
        .onAppear {
            label = existing?.label ?? ""
            type = existing?.type ?? "one_time"
            if let d = Self.date(from: existing) { date = d }
        }
    }

    private static func date(from r: ContactReminder?) -> Date? {
        guard let r else { return nil }
        var comps = DateComponents()
        comps.day = r.day; comps.month = r.month; comps.year = r.year
        return Calendar.current.date(from: comps)
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: date)
        let payload = ReminderPayload(
            label: label,
            day: comps.day,
            month: comps.month,
            year: type == "one_time" ? comps.year : nil,
            type: type,
            frequencyNumber: type == "one_time" ? nil : 1
        )
        do {
            let updated: Contact
            if let existing {
                updated = try await api.updateReminder(vaultId: vault.id, contactId: contact.id, reminderId: existing.id, payload: payload)
            } else {
                updated = try await api.createReminder(vaultId: vault.id, contactId: contact.id, payload: payload)
            }
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Contact information

struct ContactInfoEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactInformation?
    let onSaved: (Contact) -> Void

    @State private var types: [ReferenceType] = []
    @State private var selectedTypeId: Int?
    @State private var data = ""
    @State private var isLoadingTypes = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "Add Contact Info" : "Edit Contact Info",
            canSave: selectedTypeId != nil && !data.trimmingCharacters(in: .whitespaces).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Type") {
                if isLoadingTypes {
                    HStack { ProgressView(); Text("Loading types…").foregroundStyle(.secondary) }
                } else {
                    Picker("Type", selection: $selectedTypeId) {
                        ForEach(types) { type in
                            Text(type.displayName).tag(Optional(type.id))
                        }
                    }
                }
            }
            Section("Value") {
                TextField("Email, phone number…", text: $data)
                    .keyboardType(.default)
                    .textInputAutocapitalization(.never)
            }
        }
        .task { await loadTypes() }
        .onAppear { data = existing?.data ?? "" }
    }

    private func loadTypes() async {
        isLoadingTypes = true
        do {
            let ref = try await api.reference(vaultId: vault.id)
            types = ref.contactInformationTypes
            selectedTypeId = existing?.typeId ?? types.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingTypes = false
    }

    private func save() async {
        guard let typeId = selectedTypeId else { return }
        isSaving = true; errorMessage = nil
        let payload = ContactInformationPayload(contactInformationTypeId: typeId, data: data)
        do {
            let updated: Contact
            if let existing {
                updated = try await api.updateContactInformation(vaultId: vault.id, contactId: contact.id, informationId: existing.id, payload: payload)
            } else {
                updated = try await api.createContactInformation(vaultId: vault.id, contactId: contact.id, payload: payload)
            }
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Address

struct AddressEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactAddress?
    let onSaved: (Contact) -> Void

    @State private var line1 = ""
    @State private var line2 = ""
    @State private var city = ""
    @State private var province = ""
    @State private var postalCode = ""
    @State private var country = ""
    @State private var isPastAddress = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Address" : "Edit Address",
            canSave: !line1.isEmpty || !city.isEmpty || !country.isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Address") {
                TextField("Street", text: $line1)
                TextField("Apt, suite, etc.", text: $line2)
                TextField("City", text: $city)
                TextField("State / Province", text: $province)
                TextField("Postal code", text: $postalCode)
                TextField("Country", text: $country)
            }
            Section { Toggle("Past address", isOn: $isPastAddress) }
        }
        .onAppear {
            line1 = existing?.line1 ?? ""
            line2 = existing?.line2 ?? ""
            city = existing?.city ?? ""
            province = existing?.province ?? ""
            postalCode = existing?.postalCode ?? ""
            country = existing?.country ?? ""
            isPastAddress = existing?.isPastAddress ?? false
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = AddressPayload(
            line1: line1.isEmpty ? nil : line1,
            line2: line2.isEmpty ? nil : line2,
            city: city.isEmpty ? nil : city,
            province: province.isEmpty ? nil : province,
            postalCode: postalCode.isEmpty ? nil : postalCode,
            country: country.isEmpty ? nil : country,
            isPastAddress: isPastAddress
        )
        do {
            let updated: Contact
            if let existing {
                updated = try await api.updateAddress(vaultId: vault.id, contactId: contact.id, addressId: existing.id, payload: payload)
            } else {
                updated = try await api.createAddress(vaultId: vault.id, contactId: contact.id, payload: payload)
            }
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
