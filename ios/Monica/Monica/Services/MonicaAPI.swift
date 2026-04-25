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

    init(baseURL: String, token: String) {
        self.baseURL = baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        self.token = token
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
        req.httpBody = try JSONEncoder().encode(body)
        let data = try await execute(req)
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decodingError(error) }
    }

    private func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        var req = try request(for: path, method: "PUT")
        req.httpBody = try JSONEncoder().encode(body)
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
