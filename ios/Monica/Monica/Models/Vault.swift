import Foundation

struct Vault: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct VaultResponse: Codable {
    let data: [Vault]
}
