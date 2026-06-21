import SwiftUI

struct ContactDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let vault: Vault
    let contact: Contact

    @State private var full: Contact?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var activeSheet: ModuleSheet?

    private var displayed: Contact { full ?? contact }

    private var api: MonicaAPI {
        MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken)
    }

    var body: some View {
        List {
            avatarSection
            if let err = loadError {
                Section {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .onTapGesture { Task { await loadFull() } }
                }
            }
            if let infos = displayed.contactInformations, !infos.isEmpty {
                contactInfoSection(infos)
            }
            if let family = displayed.family, !family.isEmpty {
                familySection(family)
            }
            nameDetailsSection
            if let company = displayed.company {
                companySection(company)
            }
            if let dates = displayed.importantDates, !dates.isEmpty {
                datesSection(dates)
            }
            if let addrs = displayed.addresses, !addrs.isEmpty {
                addressesSection(addrs)
            }
            if let notes = displayed.notes, !notes.isEmpty {
                notesSection(notes)
            }
            if let labels = displayed.labels, !labels.isEmpty {
                labelsSection(labels)
            }
            if let groups = displayed.groups, !groups.isEmpty {
                groupsSection(groups)
            }
            if let relationships = displayed.relationships, !relationships.isEmpty {
                relationshipsSection(relationships)
            }
            if let tasks = displayed.tasks, !tasks.isEmpty {
                tasksSection(tasks)
            }
            if let calls = displayed.calls, !calls.isEmpty {
                callsSection(calls)
            }
            if let pets = displayed.pets, !pets.isEmpty {
                petsSection(pets)
            }
            if let goals = displayed.goals, !goals.isEmpty {
                goalsSection(goals)
            }
            if let facts = displayed.quickFacts, !facts.isEmpty {
                quickFactsSection(facts)
            }
            if let events = displayed.timelineEvents, !events.isEmpty {
                timelineSection(events)
            }
            if let loans = displayed.loans, !loans.isEmpty {
                loansSection(loans)
            }
            if let reminders = displayed.reminders, !reminders.isEmpty {
                remindersSection(reminders)
            }
            if let moods = displayed.moodTrackingEvents, !moods.isEmpty {
                moodSection(moods)
            }
            if let metrics = displayed.lifeMetrics, !metrics.isEmpty {
                lifeMetricsSection(metrics)
            }
            if let docs = displayed.documents, !docs.isEmpty {
                documentsSection(docs)
            }
            if let posts = displayed.posts, !posts.isEmpty {
                postsSection(posts)
            }
            if displayed.canBeDeleted {
                Section {
                    Button("Delete Contact", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle(displayed.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { activeSheet = .note(nil) } label: { Label("Note", systemImage: "note.text") }
                    Button { activeSheet = .task(nil) } label: { Label("Task", systemImage: "checklist") }
                    Button { activeSheet = .call(nil) } label: { Label("Call", systemImage: "phone") }
                    Button { activeSheet = .date(nil) } label: { Label("Important date", systemImage: "calendar") }
                    Button { activeSheet = .reminder(nil) } label: { Label("Reminder", systemImage: "bell") }
                    Button { activeSheet = .info(nil) } label: { Label("Contact info", systemImage: "envelope") }
                    Button { activeSheet = .address(nil) } label: { Label("Address", systemImage: "mappin.and.ellipse") }
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(isLoading && full == nil)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEdit = true }
                    .disabled(isLoading && full == nil)
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditContactView(vault: vault, contact: displayed) { updated in
                full = updated
            }
        }
        .sheet(item: $activeSheet) { sheet in
            moduleEditor(for: sheet)
        }
        .confirmationDialog(
            "Delete \(displayed.displayName)?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { Task { await deleteContact() } }
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
        .task { await loadFull() }
    }

    // MARK: - Sections

    @ViewBuilder
    private var avatarSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    avatarImage
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    Text(displayed.displayName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    if let nick = displayed.nickname, !nick.isEmpty {
                        Text("\u{201C}\(nick)\u{201D}")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        if let gender = displayed.gender {
                            Text(gender).font(.caption).foregroundStyle(.secondary)
                        }
                        if let pronoun = displayed.pronoun {
                            Text("(\(pronoun))").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    private var avatarImage: some View {
        CachedAvatarImage(avatar: displayed.avatar)
    }

    @ViewBuilder
    private func contactInfoSection(_ infos: [ContactInformation]) -> some View {
        Section {
            ForEach(infos) { info in
                Group {
                    if let url = info.callURL {
                        Link(destination: url) {
                            LabeledContent(info.label) {
                                Text(info.data).foregroundStyle(.blue)
                            }
                        }
                    } else {
                        LabeledContent(info.label, value: info.data)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        mutate { try await api.deleteContactInformation(vaultId: vault.id, contactId: contact.id, informationId: info.id) }
                    } label: { Label("Delete", systemImage: "trash") }
                    Button { activeSheet = .info(info) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
        } header: {
            sectionHeader("Contact", add: { activeSheet = .info(nil) })
        }
    }

    /// A section header with a trailing add (`+`) button.
    @ViewBuilder
    private func sectionHeader(_ title: String, add: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: add) { Image(systemName: "plus.circle") }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
        }
    }

    @ViewBuilder
    private var nameDetailsSection: some View {
        let fields: [(String, String?)] = [
            ("Prefix", displayed.prefix),
            ("First Name", displayed.firstName),
            ("Middle Name", displayed.middleName),
            ("Last Name", displayed.lastName),
            ("Maiden Name", displayed.maidenName),
            ("Suffix", displayed.suffix),
            ("Job", displayed.jobPosition),
            ("Religion", displayed.religion),
        ]
        let visible = fields.filter { $0.1?.isEmpty == false }
        if !visible.isEmpty {
            Section("Details") {
                ForEach(visible, id: \.0) { (label, value) in
                    LabeledContent(label, value: value!)
                }
            }
        }
    }

    @ViewBuilder
    private func companySection(_ company: ContactCompany) -> some View {
        Section("Work") {
            LabeledContent("Company", value: company.name)
        }
    }

    @ViewBuilder
    private func datesSection(_ dates: [ContactDate]) -> some View {
        Section {
            ForEach(dates) { date in
                LabeledContent(date.label ?? "Date", value: date.formatted)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            mutate { try await api.deleteImportantDate(vaultId: vault.id, contactId: contact.id, dateId: date.id) }
                        } label: { Label("Delete", systemImage: "trash") }
                        Button { activeSheet = .date(date) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                    }
            }
        } header: {
            sectionHeader("Dates", add: { activeSheet = .date(nil) })
        }
    }

    @ViewBuilder
    private func addressesSection(_ addresses: [ContactAddress]) -> some View {
        Section {
            ForEach(addresses) { addr in
                VStack(alignment: .leading, spacing: 2) {
                    Text(addr.formatted)
                        .font(.subheadline)
                    if addr.isPastAddress {
                        Text("Past address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        mutate { try await api.deleteAddress(vaultId: vault.id, contactId: contact.id, addressId: addr.id) }
                    } label: { Label("Delete", systemImage: "trash") }
                    Button { activeSheet = .address(addr) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
        } header: {
            sectionHeader("Addresses", add: { activeSheet = .address(nil) })
        }
    }

    @ViewBuilder
    private func notesSection(_ notes: [ContactNote]) -> some View {
        Section {
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 4) {
                    if let title = note.title, !title.isEmpty {
                        Text(title).font(.headline)
                    }
                    if let body = note.body, !body.isEmpty {
                        Text(body).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let emotion = note.emotion {
                        Text(emotion).font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { activeSheet = .note(note) }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        mutate { try await api.deleteNote(vaultId: vault.id, contactId: contact.id, noteId: note.id) }
                    } label: { Label("Delete", systemImage: "trash") }
                    Button { activeSheet = .note(note) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
        } header: {
            sectionHeader("Notes", add: { activeSheet = .note(nil) })
        }
    }

    @ViewBuilder
    private func labelsSection(_ labels: [ContactLabel]) -> some View {
        Section("Labels") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(labels) { label in
                        Text(label.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(hex: label.bgColor) ?? .accentColor.opacity(0.2))
                            .foregroundStyle(Color(hex: label.textColor) ?? .primary)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }

    @ViewBuilder
    private func groupsSection(_ groups: [ContactGroup]) -> some View {
        Section("Groups") {
            ForEach(groups) { group in
                if let type = group.type {
                    LabeledContent(group.name, value: type)
                } else {
                    Text(group.name)
                }
            }
        }
    }

    @ViewBuilder
    private func familySection(_ family: ContactFamily) -> some View {
        Section("Family") {
            ForEach(family.partners) { familyRow($0, role: "Partner") }
            ForEach(family.children) { familyRow($0, role: "Child") }
        }
    }

    @ViewBuilder
    private func familyRow(_ member: FamilyMember, role: String) -> some View {
        NavigationLink(value: Contact(stubId: member.contactId, vaultId: vault.id, name: member.name, avatar: member.avatar)) {
            HStack(spacing: 10) {
                ContactAvatarView(avatar: member.avatar, size: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name ?? "Unknown")
                    if let age = member.age {
                        Text("\(role) · age \(age)").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text(role).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func relationshipsSection(_ relationships: [ContactRelationship]) -> some View {
        Section("Relationships") {
            ForEach(relationships) { rel in
                NavigationLink(value: Contact(stubId: rel.contactId, vaultId: vault.id, name: rel.name, avatar: rel.avatar)) {
                    HStack(spacing: 10) {
                        ContactAvatarView(avatar: rel.avatar, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rel.name ?? "Unknown")
                                .font(.body)
                            if let type = rel.relationshipType, !type.isEmpty {
                                Text(type.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tasksSection(_ tasks: [ContactTask]) -> some View {
        Section {
            ForEach(tasks) { task in
                HStack {
                    Button {
                        mutate { try await api.toggleTask(vaultId: vault.id, contactId: contact.id, taskId: task.id) }
                    } label: {
                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.completed ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.label ?? "Task")
                            .strikethrough(task.completed)
                        if let desc = task.description, !desc.isEmpty {
                            Text(desc).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let due = task.dueAt {
                        Text(due).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { activeSheet = .task(task) }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        mutate { try await api.deleteTask(vaultId: vault.id, contactId: contact.id, taskId: task.id) }
                    } label: { Label("Delete", systemImage: "trash") }
                    Button { activeSheet = .task(task) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
        } header: {
            sectionHeader("Tasks", add: { activeSheet = .task(nil) })
        }
    }

    @ViewBuilder
    private func callsSection(_ calls: [ContactCall]) -> some View {
        Section {
            ForEach(calls) { call in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let reason = call.reason {
                            Text(reason).font(.headline)
                        }
                        Spacer()
                        if let calledAt = call.calledAt {
                            Text(calledAt).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    if let desc = call.description, !desc.isEmpty {
                        Text(desc).font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        if let answered = call.answered {
                            Text(answered ? "Answered" : "Missed")
                                .font(.caption)
                                .foregroundStyle(answered ? .green : .red)
                        }
                        if let who = call.whoInitiated {
                            Text("· initiated by \(who)").font(.caption).foregroundStyle(.secondary)
                        }
                        if let duration = call.duration, duration > 0 {
                            Text("· \(duration)min").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { activeSheet = .call(call) }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        mutate { try await api.deleteCall(vaultId: vault.id, contactId: contact.id, callId: call.id) }
                    } label: { Label("Delete", systemImage: "trash") }
                    Button { activeSheet = .call(call) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
            }
        } header: {
            sectionHeader("Calls", add: { activeSheet = .call(nil) })
        }
    }

    @ViewBuilder
    private func petsSection(_ pets: [ContactPet]) -> some View {
        Section("Pets") {
            ForEach(pets) { pet in
                if let category = pet.category {
                    LabeledContent(pet.name ?? "Pet", value: category)
                } else {
                    Text(pet.name ?? "Pet")
                }
            }
        }
    }

    @ViewBuilder
    private func goalsSection(_ goals: [ContactGoal]) -> some View {
        Section("Goals") {
            ForEach(goals) { goal in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.name ?? "Goal")
                        if !goal.active {
                            Text("Inactive").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let streak = goal.streakCount, streak > 0 {
                        Label("\(streak)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func quickFactsSection(_ facts: [ContactQuickFact]) -> some View {
        Section("Quick Facts") {
            ForEach(facts) { fact in
                if let content = fact.content, !content.isEmpty {
                    LabeledContent(fact.label ?? "Fact", value: content)
                }
            }
        }
    }

    @ViewBuilder
    private func timelineSection(_ events: [ContactTimelineEvent]) -> some View {
        Section("Timeline") {
            ForEach(events) { te in
                timelineEventRow(te)
            }
        }
    }

    @ViewBuilder
    private func timelineEventRow(_ te: ContactTimelineEvent) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(te.label ?? "Event").font(.headline)
                Spacer()
                if let startedAt = te.startedAt {
                    Text(startedAt).font(.caption2).foregroundStyle(.secondary)
                }
            }
            ForEach(te.lifeEvents, id: \.id) { le in
                lifeEventRow(le)
            }
        }
    }

    @ViewBuilder
    private func lifeEventRow(_ le: ContactLifeEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if let type = le.type {
                    Text(type).font(.subheadline).foregroundStyle(Color.accentColor)
                }
                Spacer()
                if let happenedAt = le.happenedAt {
                    Text(happenedAt).font(.caption2).foregroundStyle(.secondary)
                }
            }
            if let summary = le.summary, !summary.isEmpty {
                Text(summary).font(.subheadline)
            }
            if let costs = le.costs, let currency = le.currency {
                Text("\(currency) \(costs, format: .number)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 12)
    }

    @ViewBuilder
    private func loansSection(_ loans: [ContactLoan]) -> some View {
        Section("Loans") {
            ForEach(loans) { loan in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: loan.direction == "lent" ? "arrow.up.circle" : "arrow.down.circle")
                                .foregroundStyle(loan.direction == "lent" ? .blue : .orange)
                            Text(loan.name ?? "Loan").font(.headline)
                        }
                        if let desc = loan.description, !desc.isEmpty {
                            Text(desc).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let amount = loan.amount {
                            Text("\(loan.currency ?? "") \(amount, format: .number)")
                                .font(.subheadline.monospacedDigit())
                        }
                        Text(loan.settled ? "Settled" : "Outstanding")
                            .font(.caption)
                            .foregroundStyle(loan.settled ? .green : .red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func remindersSection(_ reminders: [ContactReminder]) -> some View {
        Section {
            ForEach(reminders) { reminder in
                reminderRow(reminder)
                    .contentShape(Rectangle())
                    .onTapGesture { activeSheet = .reminder(reminder) }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            mutate { try await api.deleteReminder(vaultId: vault.id, contactId: contact.id, reminderId: reminder.id) }
                        } label: { Label("Delete", systemImage: "trash") }
                        Button { activeSheet = .reminder(reminder) } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                    }
            }
        } header: {
            sectionHeader("Reminders", add: { activeSheet = .reminder(nil) })
        }
    }

    @ViewBuilder
    private func reminderRow(_ reminder: ContactReminder) -> some View {
        let parts: [String] = [
            reminder.month.map { Calendar.current.monthSymbols[$0 - 1] },
            reminder.day.map { String($0) },
            reminder.year.map { String($0) },
        ].compactMap { $0 }
        LabeledContent(reminder.label ?? "Reminder", value: parts.joined(separator: " "))
    }

    @ViewBuilder
    private func moodSection(_ moods: [ContactMoodEvent]) -> some View {
        Section("Mood") {
            ForEach(moods) { mood in
                HStack {
                    if let hex = mood.hexColor {
                        Circle()
                            .fill(Color(hex: hex) ?? .accentColor)
                            .frame(width: 12, height: 12)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mood.label ?? "Mood").font(.subheadline)
                        if let note = mood.note, !note.isEmpty {
                            Text(note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let hours = mood.hoursSlept {
                        Label(String(format: "%.1fh", hours), systemImage: "moon.zzz")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func lifeMetricsSection(_ metrics: [ContactLifeMetric]) -> some View {
        Section("Life Metrics") {
            ForEach(metrics) { metric in
                Text(metric.label ?? "Metric")
            }
        }
    }

    @ViewBuilder
    private func documentsSection(_ docs: [ContactDocument]) -> some View {
        Section("Documents") {
            ForEach(docs, id: \ContactDocument.id) { doc in
                documentRow(doc)
            }
        }
    }

    @ViewBuilder
    private func documentRow(_ doc: ContactDocument) -> some View {
        if let urlStr = doc.url, let url = URL(string: urlStr) {
            Link(destination: url) {
                HStack {
                    Image(systemName: mimeTypeIcon(doc.mimeType))
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.name ?? "File")
                        if let size = doc.size {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            HStack {
                Image(systemName: mimeTypeIcon(doc.mimeType))
                Text(doc.name ?? "File")
            }
        }
    }

    @ViewBuilder
    private func postsSection(_ posts: [ContactPost]) -> some View {
        Section("Journal") {
            ForEach(posts) { post in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(post.title ?? "Entry").font(.headline)
                        Spacer()
                        if let writtenAt = post.writtenAt {
                            Text(writtenAt).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    if let excerpt = post.excerpt, !excerpt.isEmpty {
                        Text(excerpt).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func mimeTypeIcon(_ mimeType: String?) -> String {
        guard let mime = mimeType else { return "doc" }
        if mime.hasPrefix("image/") { return "photo" }
        if mime.hasPrefix("video/") { return "video" }
        if mime.contains("pdf") { return "doc.richtext" }
        if mime.contains("spreadsheet") || mime.contains("excel") { return "tablecells" }
        return "doc"
    }

    // MARK: - Actions

    private func loadFull() async {
        isLoading = true
        loadError = nil
        do {
            full = try await api.contact(vaultId: vault.id, contactId: contact.id)
        } catch {
            loadError = error.localizedDescription
            #if DEBUG
            print("ContactDetailView loadFull error: \(error)")
            #endif
        }
        isLoading = false
    }

    private func deleteContact() async {
        isDeleting = true
        do {
            try await api.deleteContact(vaultId: vault.id, contactId: contact.id)
            dismiss()
        } catch {
            // stay on screen
        }
        isDeleting = false
    }

    /// Run a module delete/toggle and replace the cached contact with the
    /// fully hydrated one the server returns.
    private func mutate(_ work: @escaping () async throws -> Contact) {
        Task {
            do { full = try await work() }
            catch { loadError = error.localizedDescription }
        }
    }

    @ViewBuilder
    private func moduleEditor(for sheet: ModuleSheet) -> some View {
        let onSaved: (Contact) -> Void = { full = $0 }
        switch sheet {
        case .note(let item):
            NoteEditorView(vault: vault, contact: displayed, existing: item, onSaved: onSaved)
        case .task(let item):
            TaskEditorView(vault: vault, contact: displayed, existing: item, onSaved: onSaved)
        case .call(let item):
            CallEditorView(vault: vault, contact: displayed, existing: item, onSaved: onSaved)
        case .date(let item):
            ImportantDateEditorView(vault: vault, contact: displayed, existing: item, onSaved: onSaved)
        case .reminder(let item):
            ReminderEditorView(vault: vault, contact: displayed, existing: item, onSaved: onSaved)
        case .info(let item):
            ContactInfoEditorView(vault: vault, contact: displayed, existing: item, onSaved: onSaved)
        case .address(let item):
            AddressEditorView(vault: vault, contact: displayed, existing: item, onSaved: onSaved)
        }
    }
}

/// Identifies which module editor sheet is presented, carrying the item being
/// edited (nil = create a new one).
enum ModuleSheet: Identifiable {
    case note(ContactNote?)
    case task(ContactTask?)
    case call(ContactCall?)
    case date(ContactDate?)
    case reminder(ContactReminder?)
    case info(ContactInformation?)
    case address(ContactAddress?)

    var id: String {
        switch self {
        case .note(let i):     return "note-\(i?.id.description ?? "new")"
        case .task(let i):     return "task-\(i?.id.description ?? "new")"
        case .call(let i):     return "call-\(i?.id.description ?? "new")"
        case .date(let i):     return "date-\(i?.id.description ?? "new")"
        case .reminder(let i): return "reminder-\(i?.id.description ?? "new")"
        case .info(let i):     return "info-\(i?.id.description ?? "new")"
        case .address(let i):  return "address-\(i?.id.description ?? "new")"
        }
    }
}

// MARK: - Color+Hex

private extension Color {
    init?(hex: String?) {
        guard let hex else { return nil }
        let cleaned = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
