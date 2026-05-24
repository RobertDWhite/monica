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

    // MARK: - Contacts

    func contacts(vaultId: String) async throws -> [Contact] {
        let response: ContactResponse = try await get("/api/vaults/\(vaultId)/contacts")
        return response.data
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
