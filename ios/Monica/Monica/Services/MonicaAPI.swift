import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL."
        case .unauthorized: return "Authentication failed. Check your credentials in Settings."
        case .serverError(let code): return "Server error (\(code))."
        case .decodingError: return "Unexpected response from server."
        case .networkError(let err): return err.localizedDescription
        }
    }
}

final class MonicaAPI {
    private let baseURL: String
    private let token: String
    private let encoder: JSONEncoder

    init(baseURL: String, token: String) {
        self.baseURL = baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        self.token = token
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = enc
    }

    // MARK: - Vaults

    func vaults() async throws -> [Vault] {
        let response: VaultResponse = try await get("/api/vaults")
        return response.data
    }

    func createVault(payload: VaultPayload) async throws -> Vault {
        let w: SingleVaultResponse = try await post("/api/vaults", body: payload)
        return w.data
    }
    func updateVault(vaultId: String, payload: VaultPayload) async throws -> Vault {
        let w: SingleVaultResponse = try await put("/api/vaults/\(vaultId)", body: payload)
        return w.data
    }
    func deleteVault(vaultId: String) async throws {
        try await delete("/api/vaults/\(vaultId)")
    }

    // MARK: - Contacts

    func contacts(vaultId: String) async throws -> [Contact] {
        // include_unlisted: this no-query fetch backs the relationship picker,
        // which must be able to link to hidden ("secondary") contacts too.
        let response: ContactResponse = try await get("/api/vaults/\(vaultId)/contacts?include_unlisted=1")
        return response.data
    }

    func searchContacts(vaultId: String, query: String, page: Int) async throws -> (data: [Contact], hasMore: Bool) {
        var path = "/api/vaults/\(vaultId)/contacts?limit=100&page=\(page)"
        if !query.isEmpty, let enc = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            path += "&query=\(enc)"
        }
        let resp: ContactResponse = try await get(path)
        let hasMore = (resp.meta?.currentPage ?? 1) < (resp.meta?.lastPage ?? 1)
        return (resp.data, hasMore)
    }

    func contact(vaultId: String, contactId: String) async throws -> Contact {
        let wrapper: SingleContactResponse = try await get("/api/vaults/\(vaultId)/contacts/\(contactId)")
        return wrapper.data
    }

    func createContact(vaultId: String, payload: ContactPayload) async throws -> Contact {
        let wrapper: SingleContactResponse = try await post("/api/vaults/\(vaultId)/contacts", body: payload)
        return wrapper.data
    }

    func updateContact(vaultId: String, contactId: String, payload: ContactPayload) async throws -> Contact {
        let wrapper: SingleContactResponse = try await put("/api/vaults/\(vaultId)/contacts/\(contactId)", body: payload)
        return wrapper.data
    }

    func deleteContact(vaultId: String, contactId: String) async throws {
        try await delete("/api/vaults/\(vaultId)/contacts/\(contactId)")
    }

    // MARK: - Vault dashboard
    func vaultTasks(vaultId: String) async throws -> [VaultTask] {
        let r: DataResponse<VaultTask> = try await get("/api/vaults/\(vaultId)/dashboard/tasks")
        return r.data
    }
    func vaultReminders(vaultId: String) async throws -> [VaultReminderItem] {
        let r: DataResponse<VaultReminderItem> = try await get("/api/vaults/\(vaultId)/dashboard/reminders")
        return r.data
    }
    func vaultPosts(vaultId: String) async throws -> [VaultPostItem] {
        let r: DataResponse<VaultPostItem> = try await get("/api/vaults/\(vaultId)/dashboard/posts")
        return r.data
    }

    // MARK: - Reference data

    func reference(vaultId: String) async throws -> ReferenceData {
        let response: ReferenceResponse = try await get("/api/vaults/\(vaultId)/reference")
        return response.data
    }

    // MARK: - Contact modules
    //
    // Every module mutation returns the fully hydrated contact, so the caller
    // can replace its cached copy without an extra fetch.

    private func base(_ vaultId: String, _ contactId: String) -> String {
        "/api/vaults/\(vaultId)/contacts/\(contactId)"
    }

    // Notes
    func createNote(vaultId: String, contactId: String, payload: NotePayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/notes", method: "POST", body: payload)
    }
    func updateNote(vaultId: String, contactId: String, noteId: Int, payload: NotePayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/notes/\(noteId)", method: "PUT", body: payload)
    }
    func deleteNote(vaultId: String, contactId: String, noteId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/notes/\(noteId)", method: "DELETE")
    }

    // Tasks
    func createTask(vaultId: String, contactId: String, payload: TaskPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/tasks", method: "POST", body: payload)
    }
    func updateTask(vaultId: String, contactId: String, taskId: Int, payload: TaskPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/tasks/\(taskId)", method: "PUT", body: payload)
    }
    func toggleTask(vaultId: String, contactId: String, taskId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/tasks/\(taskId)/toggle", method: "POST")
    }
    func deleteTask(vaultId: String, contactId: String, taskId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/tasks/\(taskId)", method: "DELETE")
    }

    // Calls
    func createCall(vaultId: String, contactId: String, payload: CallPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/calls", method: "POST", body: payload)
    }
    func updateCall(vaultId: String, contactId: String, callId: Int, payload: CallPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/calls/\(callId)", method: "PUT", body: payload)
    }
    func deleteCall(vaultId: String, contactId: String, callId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/calls/\(callId)", method: "DELETE")
    }

    // Reminders
    func createReminder(vaultId: String, contactId: String, payload: ReminderPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/reminders", method: "POST", body: payload)
    }
    func updateReminder(vaultId: String, contactId: String, reminderId: Int, payload: ReminderPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/reminders/\(reminderId)", method: "PUT", body: payload)
    }
    func deleteReminder(vaultId: String, contactId: String, reminderId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/reminders/\(reminderId)", method: "DELETE")
    }

    // Important dates
    func createImportantDate(vaultId: String, contactId: String, payload: ImportantDatePayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/important-dates", method: "POST", body: payload)
    }
    func updateImportantDate(vaultId: String, contactId: String, dateId: Int, payload: ImportantDatePayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/important-dates/\(dateId)", method: "PUT", body: payload)
    }
    func deleteImportantDate(vaultId: String, contactId: String, dateId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/important-dates/\(dateId)", method: "DELETE")
    }

    // Contact information
    func createContactInformation(vaultId: String, contactId: String, payload: ContactInformationPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/contact-information", method: "POST", body: payload)
    }
    func updateContactInformation(vaultId: String, contactId: String, informationId: Int, payload: ContactInformationPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/contact-information/\(informationId)", method: "PUT", body: payload)
    }
    func deleteContactInformation(vaultId: String, contactId: String, informationId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/contact-information/\(informationId)", method: "DELETE")
    }

    // Addresses
    func createAddress(vaultId: String, contactId: String, payload: AddressPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/addresses", method: "POST", body: payload)
    }
    func updateAddress(vaultId: String, contactId: String, addressId: Int, payload: AddressPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/addresses/\(addressId)", method: "PUT", body: payload)
    }
    func deleteAddress(vaultId: String, contactId: String, addressId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/addresses/\(addressId)", method: "DELETE")
    }

    // Pets
    func createPet(vaultId: String, contactId: String, payload: PetPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/pets", method: "POST", body: payload)
    }
    func updatePet(vaultId: String, contactId: String, petId: Int, payload: PetPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/pets/\(petId)", method: "PUT", body: payload)
    }
    func deletePet(vaultId: String, contactId: String, petId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/pets/\(petId)", method: "DELETE")
    }

    // Goals
    func createGoal(vaultId: String, contactId: String, payload: GoalPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/goals", method: "POST", body: payload)
    }
    func updateGoal(vaultId: String, contactId: String, goalId: Int, payload: GoalPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/goals/\(goalId)", method: "PUT", body: payload)
    }
    func deleteGoal(vaultId: String, contactId: String, goalId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/goals/\(goalId)", method: "DELETE")
    }
    func toggleGoalStreak(vaultId: String, contactId: String, goalId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/goals/\(goalId)/streak", method: "POST")
    }

    // Quick facts
    func createQuickFact(vaultId: String, contactId: String, payload: QuickFactPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/quick-facts", method: "POST", body: payload)
    }
    func updateQuickFact(vaultId: String, contactId: String, quickFactId: Int, payload: QuickFactPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/quick-facts/\(quickFactId)", method: "PUT", body: payload)
    }
    func deleteQuickFact(vaultId: String, contactId: String, quickFactId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/quick-facts/\(quickFactId)", method: "DELETE")
    }
    func toggleQuickFacts(vaultId: String, contactId: String) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/quick-facts/toggle", method: "POST")
    }

    // Mood tracking
    func createMood(vaultId: String, contactId: String, payload: MoodPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/mood-tracking", method: "POST", body: payload)
    }
    func updateMood(vaultId: String, contactId: String, eventId: Int, payload: MoodPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/mood-tracking/\(eventId)", method: "PUT", body: payload)
    }
    func deleteMood(vaultId: String, contactId: String, eventId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/mood-tracking/\(eventId)", method: "DELETE")
    }

    // Loans
    func createLoan(vaultId: String, contactId: String, payload: LoanPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/loans", method: "POST", body: payload)
    }
    func updateLoan(vaultId: String, contactId: String, loanId: Int, payload: LoanPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/loans/\(loanId)", method: "PUT", body: payload)
    }
    func deleteLoan(vaultId: String, contactId: String, loanId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/loans/\(loanId)", method: "DELETE")
    }
    func toggleLoan(vaultId: String, contactId: String, loanId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/loans/\(loanId)/toggle", method: "POST")
    }

    // Relationships
    func setRelationship(vaultId: String, contactId: String, payload: RelationshipPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/relationships", method: "POST", body: payload)
    }
    func unsetRelationship(vaultId: String, contactId: String, payload: RelationshipPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/relationships", method: "DELETE", body: payload)
    }

    // Labels
    func assignLabel(vaultId: String, contactId: String, payload: LabelPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/labels", method: "POST", body: payload)
    }
    func removeLabel(vaultId: String, contactId: String, labelId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/labels/\(labelId)", method: "DELETE")
    }

    // Groups
    func addGroup(vaultId: String, contactId: String, payload: GroupPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/groups", method: "POST", body: payload)
    }
    func removeGroup(vaultId: String, contactId: String, groupId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/groups/\(groupId)", method: "DELETE")
    }

    // Religion
    func updateReligion(vaultId: String, contactId: String, payload: ReligionPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/religion", method: "PUT", body: payload)
    }

    // Life events
    func createLifeEvent(vaultId: String, contactId: String, payload: LifeEventPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/life-events", method: "POST", body: payload)
    }
    func updateLifeEvent(vaultId: String, contactId: String, timelineId: Int, lifeEventId: Int, payload: LifeEventPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/life-events/\(timelineId)/\(lifeEventId)", method: "PUT", body: payload)
    }
    func deleteLifeEvent(vaultId: String, contactId: String, timelineId: Int, lifeEventId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/life-events/\(timelineId)/\(lifeEventId)", method: "DELETE")
    }
    func toggleLifeEvent(vaultId: String, contactId: String, timelineId: Int, lifeEventId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/life-events/\(timelineId)/\(lifeEventId)/toggle", method: "POST")
    }

    // Job information
    func updateJob(vaultId: String, contactId: String, payload: JobPayload) async throws -> Contact {
        try await mutate(base(vaultId, contactId) + "/job", method: "PUT", body: payload)
    }

    // Avatar
    func uploadAvatar(vaultId: String, contactId: String, data: Data, fileName: String, mimeType: String) async throws -> Contact {
        try await uploadMultipart(base(vaultId, contactId) + "/avatar", fieldName: "photo", fileName: fileName, mimeType: mimeType, data: data)
    }
    func deleteAvatar(vaultId: String, contactId: String) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/avatar", method: "DELETE")
    }

    // Photos
    func uploadPhoto(vaultId: String, contactId: String, data: Data, fileName: String, mimeType: String) async throws -> Contact {
        try await uploadMultipart(base(vaultId, contactId) + "/photos", fieldName: "photo", fileName: fileName, mimeType: mimeType, data: data)
    }
    func deletePhoto(vaultId: String, contactId: String, fileId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/photos/\(fileId)", method: "DELETE")
    }

    // Documents
    func uploadDocument(vaultId: String, contactId: String, data: Data, fileName: String, mimeType: String) async throws -> Contact {
        try await uploadMultipart(base(vaultId, contactId) + "/documents", fieldName: "document", fileName: fileName, mimeType: mimeType, data: data)
    }
    func deleteDocument(vaultId: String, contactId: String, fileId: Int) async throws -> Contact {
        try await mutateNoBody(base(vaultId, contactId) + "/documents/\(fileId)", method: "DELETE")
    }

    // MARK: - Mutation helpers

    private func mutate<B: Encodable>(_ path: String, method: String, body: B) async throws -> Contact {
        var req = try request(for: path, method: method)
        req.httpBody = try encoder.encode(body)
        let data = try await execute(req)
        do { return try JSONDecoder().decode(SingleContactResponse.self, from: data).data }
        catch { throw APIError.decodingError(error) }
    }

    private func mutateNoBody(_ path: String, method: String) async throws -> Contact {
        let req = try request(for: path, method: method)
        let data = try await execute(req)
        do { return try JSONDecoder().decode(SingleContactResponse.self, from: data).data }
        catch { throw APIError.decodingError(error) }
    }

    private func uploadMultipart(_ path: String, fieldName: String, fileName: String, mimeType: String, data: Data) async throws -> Contact {
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = try request(for: path, method: "POST")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        let respData = try await execute(req)
        do { return try JSONDecoder().decode(SingleContactResponse.self, from: respData).data }
        catch { throw APIError.decodingError(error) }
    }

    // MARK: - Helpers

    private func request(for path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    private func execute(_ req: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        switch http.statusCode {
        case 200...299: return data
        case 401: throw APIError.unauthorized
        default: throw APIError.serverError(http.statusCode)
        }
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let req = try request(for: path, method: "GET")
        let data = try await execute(req)
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var req = try request(for: path, method: "POST")
        req.httpBody = try encoder.encode(body)
        let data = try await execute(req)
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }

    private func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var req = try request(for: path, method: "PUT")
        req.httpBody = try encoder.encode(body)
        let data = try await execute(req)
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }

    private func delete(_ path: String) async throws {
        let req = try request(for: path, method: "DELETE")
        _ = try await execute(req)
    }
}

private struct SingleContactResponse: Codable {
    let data: Contact
}

private struct SingleVaultResponse: Codable {
    let data: Vault
}
