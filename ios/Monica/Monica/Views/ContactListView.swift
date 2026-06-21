import SwiftUI

struct ContactListView: View {
    @Environment(AppState.self) private var appState
    let vault: Vault

    @State private var contacts: [Contact] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var page = 1
    @State private var hasMore = false
    @State private var showAddContact = false
    @State private var showDashboard = false

    private var api: MonicaAPI {
        MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken)
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
                    Button("Retry") { Task { await reload() } }
                }
            } else if contacts.isEmpty {
                ContentUnavailableView(searchText.isEmpty ? "No Contacts" : "No Results",
                                       systemImage: "person.2")
            } else {
                List {
                    ForEach(contacts) { contact in
                        NavigationLink(value: contact) {
                            HStack(spacing: 12) {
                                ContactAvatarView(avatar: contact.avatar, size: 40)
                                VStack(alignment: .leading) {
                                    Text(contact.displayName).font(.headline)
                                    if let nickname = contact.nickname, !nickname.isEmpty {
                                        Text("\u{201C}\(nickname)\u{201D}")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onAppear {
                            if contact.id == contacts.last?.id { Task { await loadMore() } }
                        }
                    }
                    if isLoadingMore {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    }
                }
                .refreshable { await reload() }
            }
        }
        .searchable(text: $searchText, prompt: "Search contacts")
        .navigationTitle(vault.name)
        .navigationDestination(for: Contact.self) { contact in
            ContactDetailView(vault: vault, contact: contact)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showDashboard = true } label: { Image(systemName: "square.grid.2x2") }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddContact = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddContact) {
            AddEditContactView(vault: vault) { _ in Task { await reload() } }
        }
        .sheet(isPresented: $showDashboard) {
            VaultDashboardView(vault: vault)
        }
        .task(id: searchText) {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            await reload()
        }
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            let r = try await api.searchContacts(vaultId: vault.id, query: searchText, page: 1)
            contacts = r.data
            hasMore = r.hasMore
            page = 1
        } catch APIError.unauthorized {
            appState.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        do {
            let r = try await api.searchContacts(vaultId: vault.id, query: searchText, page: page + 1)
            contacts += r.data
            page += 1
            hasMore = r.hasMore
        } catch {
            // keep what we have
        }
        isLoadingMore = false
    }
}


struct VaultDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let vault: Vault

    @State private var tasks: [VaultTask] = []
    @State private var reminders: [VaultReminderItem] = []
    @State private var posts: [VaultPostItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var api: MonicaAPI { MonicaAPI(baseURL: appState.serverURL, token: appState.apiToken) }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Section { Label(errorMessage, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                }
                Section("Due Tasks") {
                    if tasks.isEmpty { Text("No open tasks").font(.caption).foregroundStyle(.secondary) }
                    ForEach(tasks) { task in
                        HStack(spacing: 10) {
                            Button { Task { await toggle(task) } } label: {
                                Image(systemName: "circle").foregroundStyle(.secondary)
                            }.buttonStyle(.plain)
                            NavigationLink(value: stub(task.contact)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.label ?? "Task")
                                    Text(task.contact.name ?? "Unknown").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let due = task.dueAt { Text(due).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                }
                Section("Upcoming Reminders") {
                    if reminders.isEmpty { Text("No reminders").font(.caption).foregroundStyle(.secondary) }
                    ForEach(reminders) { r in
                        NavigationLink(value: stub(r.contact)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.label ?? "Reminder")
                                Text("\(r.contact.name ?? "Unknown") · \(r.dateText)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Recent Journal") {
                    if posts.isEmpty { Text("No entries").font(.caption).foregroundStyle(.secondary) }
                    ForEach(posts) { p in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.title ?? "Entry")
                            Text([p.journal, p.writtenAt].compactMap { $0 }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Contact.self) { c in
                ContactDetailView(vault: vault, contact: c)
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .overlay {
                if isLoading && tasks.isEmpty && reminders.isEmpty && posts.isEmpty { ProgressView() }
            }
        }
        .task { await loadAll() }
    }

    private func stub(_ c: DashboardContact) -> Contact {
        Contact(stubId: c.id, vaultId: vault.id, name: c.name, avatar: c.avatar)
    }

    private func loadAll() async {
        isLoading = true; errorMessage = nil
        do {
            async let t = api.vaultTasks(vaultId: vault.id)
            async let r = api.vaultReminders(vaultId: vault.id)
            async let p = api.vaultPosts(vaultId: vault.id)
            tasks = try await t
            reminders = try await r
            posts = try await p
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func toggle(_ task: VaultTask) async {
        do {
            _ = try await api.toggleTask(vaultId: vault.id, contactId: task.contact.id, taskId: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch { errorMessage = error.localizedDescription }
    }
}
