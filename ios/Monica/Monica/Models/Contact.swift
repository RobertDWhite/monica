import Foundation

struct Contact: Identifiable, Codable, Hashable {
    let id: String
    let vaultId: String
    let firstName: String?
    let lastName: String?
    let middleName: String?
    let nickname: String?
    let maidenName: String?
    let prefix: String?
    let suffix: String?
    let listed: Bool
    let canBeDeleted: Bool
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case vaultId = "vault_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case middleName = "middle_name"
        case nickname
        case maidenName = "maiden_name"
        case prefix, suffix, listed
        case canBeDeleted = "can_be_deleted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayName: String {
        let parts = [prefix, firstName, middleName, lastName, suffix]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
        let full = parts.joined(separator: " ")
        return full.isEmpty ? (nickname ?? "Unnamed Contact") : full
    }
}

struct ContactResponse: Codable {
    let data: [Contact]
}

struct ContactPayload: Codable {
    var firstName: String
    var lastName: String
    var middleName: String
    var nickname: String
    var prefix: String
    var suffix: String
    var listed: Bool

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case middleName = "middle_name"
        case nickname, prefix, suffix, listed
    }
}
