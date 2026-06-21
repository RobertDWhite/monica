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

// MARK: - Pet

struct PetEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactPet?
    let onSaved: (Contact) -> Void

    @State private var name = ""
    @State private var categories: [ReferenceType] = []
    @State private var categoryId: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Pet" : "Edit Pet",
            canSave: categoryId != nil,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Category") {
                Picker("Category", selection: $categoryId) {
                    ForEach(categories) { c in Text(c.displayName).tag(Optional(c.id)) }
                }
            }
            Section("Name") { TextField("Name (optional)", text: $name) }
        }
        .task { await loadCategories() }
        .onAppear { name = existing?.name ?? "" }
    }

    private func loadCategories() async {
        do {
            let ref = try await api.reference(vaultId: vault.id)
            categories = ref.petCategories
            categoryId = categories.first(where: { $0.displayName == existing?.category })?.id ?? categories.first?.id
        } catch { errorMessage = error.localizedDescription }
    }

    private func save() async {
        guard let categoryId else { return }
        isSaving = true; errorMessage = nil
        let payload = PetPayload(petCategoryId: categoryId, name: name.isEmpty ? nil : name)
        do {
            let updated = existing == nil
                ? try await api.createPet(vaultId: vault.id, contactId: contact.id, payload: payload)
                : try await api.updatePet(vaultId: vault.id, contactId: contact.id, petId: existing!.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Goal

struct GoalEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactGoal?
    let onSaved: (Contact) -> Void

    @State private var name = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Goal" : "Edit Goal",
            canSave: !name.trimmingCharacters(in: .whitespaces).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Goal") { TextField("e.g. Call every week", text: $name) }
        }
        .onAppear { name = existing?.name ?? "" }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = GoalPayload(name: name)
        do {
            let updated = existing == nil
                ? try await api.createGoal(vaultId: vault.id, contactId: contact.id, payload: payload)
                : try await api.updateGoal(vaultId: vault.id, contactId: contact.id, goalId: existing!.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Quick fact

struct QuickFactEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactQuickFact?
    let onSaved: (Contact) -> Void

    @State private var content = ""
    @State private var templates: [ReferenceType] = []
    @State private var templateId: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Quick Fact" : "Edit Quick Fact",
            canSave: !content.trimmingCharacters(in: .whitespaces).isEmpty && (existing != nil || templateId != nil),
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            if existing == nil {
                Section("Label") {
                    Picker("Label", selection: $templateId) {
                        ForEach(templates) { t in Text(t.displayName).tag(Optional(t.id)) }
                    }
                }
            }
            Section("Fact") {
                TextField("e.g. Allergic to peanuts", text: $content, axis: .vertical).lineLimit(2...5)
            }
        }
        .task {
            if existing == nil {
                let ref = try? await api.reference(vaultId: vault.id)
                templates = ref?.quickFactTemplates ?? []
                templateId = templates.first?.id
            }
        }
        .onAppear { content = existing?.content ?? "" }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = QuickFactPayload(vaultQuickFactsTemplateId: templateId, content: content)
        do {
            let updated = existing == nil
                ? try await api.createQuickFact(vaultId: vault.id, contactId: contact.id, payload: payload)
                : try await api.updateQuickFact(vaultId: vault.id, contactId: contact.id, quickFactId: existing!.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Mood

struct MoodEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactMoodEvent?
    let onSaved: (Contact) -> Void

    @State private var parameters: [MoodParameterRef] = []
    @State private var parameterId: Int?
    @State private var ratedAt = Date()
    @State private var note = ""
    @State private var hasSleep = false
    @State private var hoursSlept = 8
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "Record Mood" : "Edit Mood",
            canSave: parameterId != nil,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Mood") {
                Picker("Mood", selection: $parameterId) {
                    ForEach(parameters) { p in Text(p.label ?? "Mood").tag(Optional(p.id)) }
                }
                DatePicker("When", selection: $ratedAt, displayedComponents: .date)
            }
            Section("Sleep") {
                Toggle("Track hours slept", isOn: $hasSleep)
                if hasSleep { Stepper("\(hoursSlept)h", value: $hoursSlept, in: 0...24) }
            }
            Section("Note") {
                TextField("Optional note", text: $note, axis: .vertical).lineLimit(2...5)
            }
        }
        .task { await loadParameters() }
        .onAppear {
            note = existing?.note ?? ""
            if let h = existing?.hoursSlept { hasSleep = true; hoursSlept = Int(h) }
            if let s = existing?.ratedAt, let d = ISO8601DateFormatter().date(from: s) { ratedAt = d }
        }
    }

    private func loadParameters() async {
        do {
            let ref = try await api.reference(vaultId: vault.id)
            parameters = ref.moodParameters
            parameterId = parameters.first(where: { $0.label == existing?.label })?.id ?? parameters.first?.id
        } catch { errorMessage = error.localizedDescription }
    }

    private func save() async {
        guard let parameterId else { return }
        isSaving = true; errorMessage = nil
        let payload = MoodPayload(
            moodTrackingParameterId: parameterId,
            ratedAt: apiDateFormatter.string(from: ratedAt),
            note: note.isEmpty ? nil : note,
            numberOfHoursSlept: hasSleep ? hoursSlept : nil
        )
        do {
            let updated = existing == nil
                ? try await api.createMood(vaultId: vault.id, contactId: contact.id, payload: payload)
                : try await api.updateMood(vaultId: vault.id, contactId: contact.id, eventId: existing!.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Loan

struct LoanEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let existing: ContactLoan?
    let onSaved: (Contact) -> Void

    @State private var type = "object"
    @State private var name = ""
    @State private var description = ""
    @State private var contactOwes = true   // true: contact owes me; false: I owe contact
    @State private var hasAmount = false
    @State private var amount = 0
    @State private var loanedAt = Date()
    @State private var currencies: [CurrencyRef] = []
    @State private var currencyId: Int?
    @State private var meContactId: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: existing == nil ? "New Loan" : "Edit Loan",
            canSave: !name.trimmingCharacters(in: .whitespaces).isEmpty && meContactId != nil,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section {
                Picker("Type", selection: $type) {
                    Text("Object").tag("object")
                    Text("Money").tag("money")
                }
                Picker("Direction", selection: $contactOwes) {
                    Text("\(contact.displayName) owes me").tag(true)
                    Text("I owe \(contact.displayName)").tag(false)
                }
            }
            Section("Details") {
                TextField("What was loaned", text: $name)
                TextField("Notes (optional)", text: $description, axis: .vertical).lineLimit(2...4)
                DatePicker("Date", selection: $loanedAt, displayedComponents: .date)
            }
            if type == "money" {
                Section("Amount") {
                    Toggle("Set amount", isOn: $hasAmount)
                    if hasAmount {
                        Stepper("\(amount)", value: $amount, in: 0...1000000, step: 1)
                        if !currencies.isEmpty {
                            Picker("Currency", selection: $currencyId) {
                                ForEach(currencies) { c in Text(c.code).tag(Optional(c.id)) }
                            }
                        }
                    }
                }
            }
            if meContactId == nil {
                Section {
                    Text("Your own contact isn't set up in this vault, so loans can't be attributed.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .task { await loadReference() }
        .onAppear {
            name = existing?.name ?? ""
            description = existing?.description ?? ""
            contactOwes = existing?.direction == "lent" ? false : true
            if let a = existing?.amount, a > 0 { hasAmount = true; amount = Int(a); type = "money" }
        }
    }

    private func loadReference() async {
        do {
            let ref = try await api.reference(vaultId: vault.id)
            currencies = ref.currencies
            currencyId = currencies.first?.id
            meContactId = ref.meContactId
        } catch { errorMessage = error.localizedDescription }
    }

    private func save() async {
        guard let meContactId else { return }
        isSaving = true; errorMessage = nil
        // contactOwes: contact is the loanee (borrower), I am the loaner (lender)
        let loaners = contactOwes ? [meContactId] : [contact.id]
        let loanees = contactOwes ? [contact.id] : [meContactId]
        let payload = LoanPayload(
            type: type,
            name: name,
            description: description.isEmpty ? nil : description,
            amountLent: (type == "money" && hasAmount) ? amount : nil,
            currencyId: (type == "money" && hasAmount) ? currencyId : nil,
            loanedAt: apiDateFormatter.string(from: loanedAt),
            loanerIds: loaners,
            loaneeIds: loanees
        )
        do {
            let updated = existing == nil
                ? try await api.createLoan(vaultId: vault.id, contactId: contact.id, payload: payload)
                : try await api.updateLoan(vaultId: vault.id, contactId: contact.id, loanId: existing!.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Relationship

struct RelationshipEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let onSaved: (Contact) -> Void

    @State private var types: [RelationshipTypeRef] = []
    @State private var typeId: Int?
    @State private var contacts: [Contact] = []
    @State private var otherContactId: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: "Add Relationship",
            canSave: typeId != nil && otherContactId != nil,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Relationship") {
                Picker("Type", selection: $typeId) {
                    Text("Select…").tag(Optional<Int>.none)
                    ForEach(types) { t in
                        Text(t.group != nil ? "\(t.displayName) (\(t.group!))" : t.displayName).tag(Optional(t.id))
                    }
                }
            }
            Section("Person") {
                Picker("Person", selection: $otherContactId) {
                    Text("Select…").tag(Optional<String>.none)
                    ForEach(contacts.filter { $0.id != contact.id }) { c in
                        Text(c.displayName).tag(Optional(c.id))
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        do {
            async let ref = api.reference(vaultId: vault.id)
            async let list = api.contacts(vaultId: vault.id)
            types = try await ref.relationshipTypes
            contacts = try await list
            typeId = types.first?.id
        } catch { errorMessage = error.localizedDescription }
    }

    private func save() async {
        guard let typeId, let otherContactId else { return }
        isSaving = true; errorMessage = nil
        let payload = RelationshipPayload(relationshipTypeId: typeId, otherContactId: otherContactId)
        do {
            let updated = try await api.setRelationship(vaultId: vault.id, contactId: contact.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Label

struct LabelEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let onSaved: (Contact) -> Void

    @State private var labels: [ContactLabel] = []
    @State private var labelId: Int?
    @State private var newName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: "Add Label",
            canSave: labelId != nil || !newName.trimmingCharacters(in: .whitespaces).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            if !labels.isEmpty {
                Section("Existing label") {
                    Picker("Label", selection: $labelId) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(labels) { l in Text(l.name).tag(Optional(l.id)) }
                    }
                }
            }
            Section("Or create new") {
                TextField("New label name", text: $newName)
            }
        }
        .task { labels = (try? await api.reference(vaultId: vault.id))?.labels ?? [] }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        let payload = trimmed.isEmpty
            ? LabelPayload(labelId: labelId, name: nil)
            : LabelPayload(labelId: nil, name: trimmed)
        do {
            let updated = try await api.assignLabel(vaultId: vault.id, contactId: contact.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Group

struct GroupEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let onSaved: (Contact) -> Void

    @State private var groups: [ContactGroup] = []
    @State private var groupId: Int?
    @State private var groupTypes: [GroupTypeRef] = []
    @State private var groupTypeId: Int?
    @State private var newName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: "Add to Group",
            canSave: groupId != nil || !newName.trimmingCharacters(in: .whitespaces).isEmpty,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            if !groups.isEmpty {
                Section("Existing group") {
                    Picker("Group", selection: $groupId) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(groups) { g in Text(g.name).tag(Optional(g.id)) }
                    }
                }
            }
            Section("Or create new") {
                TextField("New group name", text: $newName)
                if !groupTypes.isEmpty {
                    Picker("Type", selection: $groupTypeId) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(groupTypes) { t in Text(t.label ?? "Type").tag(Optional(t.id)) }
                    }
                }
            }
        }
        .task {
            let ref = try? await api.reference(vaultId: vault.id)
            groups = ref?.groups ?? []
            groupTypes = ref?.groupTypes ?? []
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        let payload = trimmed.isEmpty
            ? GroupPayload(groupId: groupId, name: nil, groupTypeId: nil)
            : GroupPayload(groupId: nil, name: trimmed, groupTypeId: groupTypeId)
        do {
            let updated = try await api.addGroup(vaultId: vault.id, contactId: contact.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Religion

struct ReligionEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let onSaved: (Contact) -> Void

    @State private var religions: [ReferenceType] = []
    @State private var religionId: Int?
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: "Religion",
            canSave: religionId != nil,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Religion") {
                Picker("Religion", selection: $religionId) {
                    ForEach(religions) { r in Text(r.displayName).tag(Optional(r.id)) }
                }
            }
        }
        .task {
            religions = (try? await api.reference(vaultId: vault.id))?.religions ?? []
            religionId = contact.religionId ?? religions.first?.id
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let payload = ReligionPayload(religionId: religionId)
        do {
            let updated = try await api.updateReligion(vaultId: vault.id, contactId: contact.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Life event

struct LifeEventEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let onSaved: (Contact) -> Void

    @State private var categories: [LifeEventCategoryRef] = []
    @State private var typeId: Int?
    @State private var summary = ""
    @State private var description = ""
    @State private var happenedAt = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: "New Life Event",
            canSave: typeId != nil,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Type") {
                Picker("Type", selection: $typeId) {
                    Text("Select…").tag(Optional<Int>.none)
                    ForEach(categories) { cat in
                        ForEach(cat.types) { t in
                            Text("\(cat.label ?? "") · \(t.label ?? "")").tag(Optional(t.id))
                        }
                    }
                }
            }
            Section("Details") {
                TextField("Summary", text: $summary)
                TextField("Description (optional)", text: $description, axis: .vertical).lineLimit(2...5)
                DatePicker("When", selection: $happenedAt, displayedComponents: .date)
            }
        }
        .task {
            categories = (try? await api.reference(vaultId: vault.id))?.lifeEventCategories ?? []
            typeId = categories.first?.types.first?.id
        }
    }

    private func save() async {
        guard let typeId else { return }
        isSaving = true; errorMessage = nil
        let payload = LifeEventPayload(
            lifeEventTypeId: typeId,
            summary: summary.isEmpty ? nil : summary,
            description: description.isEmpty ? nil : description,
            happenedAt: apiDateFormatter.string(from: happenedAt),
            costs: nil,
            currencyId: nil
        )
        do {
            let updated = try await api.createLifeEvent(vaultId: vault.id, contactId: contact.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

// MARK: - Job information

struct JobEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact
    let onSaved: (Contact) -> Void

    @State private var jobPosition = ""
    @State private var companies: [ContactCompany] = []
    @State private var companyId: Int?
    @State private var newCompany = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        EditorScaffold(
            title: "Job & Company",
            canSave: true,
            errorMessage: $errorMessage,
            isSaving: $isSaving,
            onSave: save
        ) {
            Section("Job") {
                TextField("Job title", text: $jobPosition)
            }
            Section("Company") {
                if !companies.isEmpty {
                    Picker("Company", selection: $companyId) {
                        Text("None").tag(Optional<Int>.none)
                        ForEach(companies, id: \.id) { c in Text(c.name).tag(Optional(c.id)) }
                    }
                }
                TextField("Or new company", text: $newCompany)
            }
        }
        .task { companies = (try? await api.reference(vaultId: vault.id))?.companies ?? [] }
        .onAppear {
            jobPosition = contact.jobPosition ?? ""
            companyId = contact.company?.id
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        let trimmed = newCompany.trimmingCharacters(in: .whitespaces)
        let payload = JobPayload(
            jobPosition: jobPosition.isEmpty ? nil : jobPosition,
            companyId: trimmed.isEmpty ? companyId : nil,
            companyName: trimmed.isEmpty ? nil : trimmed
        )
        do {
            let updated = try await api.updateJob(vaultId: vault.id, contactId: contact.id, payload: payload)
            onSaved(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}
