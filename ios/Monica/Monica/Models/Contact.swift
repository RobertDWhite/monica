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
    let avatar: ContactAvatar?
    let gender: String?
    let pronoun: String?
    let religion: String?
    let jobPosition: String?
    let company: ContactCompany?
    let contactInformations: [ContactInformation]?
    let importantDates: [ContactDate]?
    let addresses: [ContactAddress]?
    let notes: [ContactNote]?
    let labels: [ContactLabel]?
    let groups: [ContactGroup]?
    let relationships: [ContactRelationship]?
    let tasks: [ContactTask]?
    let calls: [ContactCall]?
    let pets: [ContactPet]?
    let goals: [ContactGoal]?
    let quickFacts: [ContactQuickFact]?
    let timelineEvents: [ContactTimelineEvent]?
    let loans: [ContactLoan]?
    let reminders: [ContactReminder]?
    let moodTrackingEvents: [ContactMoodEvent]?
    let lifeMetrics: [ContactLifeMetric]?
    let documents: [ContactDocument]?
    let posts: [ContactPost]?
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
        case avatar, gender, pronoun, religion
        case jobPosition = "job_position"
        case company
        case contactInformations = "contact_informations"
        case importantDates = "important_dates"
        case addresses, notes, labels, groups, relationships, tasks, calls, pets, goals
        case quickFacts = "quick_facts"
        case timelineEvents = "timeline_events"
        case loans, reminders
        case moodTrackingEvents = "mood_tracking_events"
        case lifeMetrics = "life_metrics"
        case documents, posts
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Required fields — failure here is intentional
        id            = try c.decode(String.self, forKey: .id)
        vaultId       = try c.decode(String.self, forKey: .vaultId)
        listed        = try c.decode(Bool.self,   forKey: .listed)
        canBeDeleted  = try c.decode(Bool.self,   forKey: .canBeDeleted)
        // Scalar optionals
        firstName     = try? c.decodeIfPresent(String.self, forKey: .firstName)
        lastName      = try? c.decodeIfPresent(String.self, forKey: .lastName)
        middleName    = try? c.decodeIfPresent(String.self, forKey: .middleName)
        nickname      = try? c.decodeIfPresent(String.self, forKey: .nickname)
        maidenName    = try? c.decodeIfPresent(String.self, forKey: .maidenName)
        prefix        = try? c.decodeIfPresent(String.self, forKey: .prefix)
        suffix        = try? c.decodeIfPresent(String.self, forKey: .suffix)
        gender        = try? c.decodeIfPresent(String.self, forKey: .gender)
        pronoun       = try? c.decodeIfPresent(String.self, forKey: .pronoun)
        religion      = try? c.decodeIfPresent(String.self, forKey: .religion)
        jobPosition   = try? c.decodeIfPresent(String.self, forKey: .jobPosition)
        createdAt     = try? c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt     = try? c.decodeIfPresent(String.self, forKey: .updatedAt)
        // Struct optionals — isolated so one bad field can't kill the whole decode
        avatar        = try? c.decodeIfPresent(ContactAvatar.self,           forKey: .avatar)
        company       = try? c.decodeIfPresent(ContactCompany.self,          forKey: .company)
        contactInformations = try? c.decodeIfPresent([ContactInformation].self, forKey: .contactInformations)
        importantDates      = try? c.decodeIfPresent([ContactDate].self,        forKey: .importantDates)
        addresses           = try? c.decodeIfPresent([ContactAddress].self,     forKey: .addresses)
        notes               = try? c.decodeIfPresent([ContactNote].self,        forKey: .notes)
        labels              = try? c.decodeIfPresent([ContactLabel].self,       forKey: .labels)
        groups              = try? c.decodeIfPresent([ContactGroup].self,       forKey: .groups)
        relationships       = try? c.decodeIfPresent([ContactRelationship].self, forKey: .relationships)
        tasks               = try? c.decodeIfPresent([ContactTask].self,        forKey: .tasks)
        calls               = try? c.decodeIfPresent([ContactCall].self,        forKey: .calls)
        pets                = try? c.decodeIfPresent([ContactPet].self,         forKey: .pets)
        goals               = try? c.decodeIfPresent([ContactGoal].self,        forKey: .goals)
        quickFacts          = try? c.decodeIfPresent([ContactQuickFact].self,   forKey: .quickFacts)
        timelineEvents      = try? c.decodeIfPresent([ContactTimelineEvent].self, forKey: .timelineEvents)
        loans               = try? c.decodeIfPresent([ContactLoan].self,        forKey: .loans)
        reminders           = try? c.decodeIfPresent([ContactReminder].self,    forKey: .reminders)
        moodTrackingEvents  = try? c.decodeIfPresent([ContactMoodEvent].self,   forKey: .moodTrackingEvents)
        lifeMetrics         = try? c.decodeIfPresent([ContactLifeMetric].self,  forKey: .lifeMetrics)
        documents           = try? c.decodeIfPresent([ContactDocument].self,    forKey: .documents)
        posts               = try? c.decodeIfPresent([ContactPost].self,        forKey: .posts)
    }

    var displayName: String {
        let parts = [prefix, firstName, middleName, lastName, suffix]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
        let full = parts.joined(separator: " ")
        return full.isEmpty ? (nickname ?? "Unnamed Contact") : full
    }
}

struct ContactAvatar: Codable, Hashable {
    let type: String
    let content: String
}

struct ContactCompany: Codable, Hashable {
    let id: Int
    let name: String
}

struct ContactInformation: Identifiable, Codable, Hashable {
    let id: Int
    let label: String
    let type: String?
    let `protocol`: String?
    let data: String

    var callURL: URL? {
        guard let proto = `protocol`, !proto.isEmpty else { return nil }
        return URL(string: proto + data)
    }
}

struct ContactDate: Identifiable, Codable, Hashable {
    let id: String
    let label: String?
    let day: Int?
    let month: Int?
    let year: Int?

    var formatted: String {
        let parts: [String] = [
            month.map { Calendar.current.monthSymbols[$0 - 1] },
            day.map { String($0) },
            year.map { String($0) },
        ].compactMap { $0 }
        return parts.isEmpty ? "Unknown" : parts.joined(separator: " ")
    }
}

struct ContactAddress: Identifiable, Codable, Hashable {
    let id: Int
    let line1: String?
    let line2: String?
    let city: String?
    let province: String?
    let postalCode: String?
    let country: String?
    let isPastAddress: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case line1 = "line_1"
        case line2 = "line_2"
        case city, province
        case postalCode = "postal_code"
        case country
        case isPastAddress = "is_past_address"
    }

    var formatted: String {
        [line1, line2, city, province, postalCode, country]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: ", ")
    }
}

struct ContactNote: Identifiable, Codable, Hashable {
    let id: Int
    let title: String?
    let body: String?
    let emotion: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, body, emotion
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ContactLabel: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let bgColor: String?
    let textColor: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case bgColor = "bg_color"
        case textColor = "text_color"
    }
}

struct ContactGroup: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: String?
}

struct ContactRelationship: Codable, Hashable {
    let contactId: String
    let name: String?
    let avatar: ContactAvatar?
    let relationshipType: String?

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case name, avatar
        case relationshipType = "relationship_type"
    }
}

struct ContactTask: Identifiable, Codable, Hashable {
    let id: String
    let label: String?
    let description: String?
    let completed: Bool
    let dueAt: String?

    enum CodingKeys: String, CodingKey {
        case id, label, description, completed
        case dueAt = "due_at"
    }
}

struct ContactCall: Identifiable, Codable, Hashable {
    let id: Int
    let reason: String?
    let description: String?
    let calledAt: String?
    let duration: Int?
    let type: String?
    let answered: Bool?
    let whoInitiated: String?
    let emotion: String?

    enum CodingKeys: String, CodingKey {
        case id, reason, description
        case calledAt = "called_at"
        case duration, type, answered
        case whoInitiated = "who_initiated"
        case emotion
    }
}

struct ContactPet: Identifiable, Codable, Hashable {
    let id: Int
    let name: String?
    let category: String?
}

struct ContactGoal: Identifiable, Codable, Hashable {
    let id: Int
    let name: String?
    let active: Bool
    let streakCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, active
        case streakCount = "streak_count"
    }
}

struct ContactQuickFact: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let content: String?
}

struct ContactTimelineEvent: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let startedAt: String?
    let lifeEvents: [ContactLifeEvent]

    enum CodingKeys: String, CodingKey {
        case id, label
        case startedAt = "started_at"
        case lifeEvents = "life_events"
    }
}

struct ContactLifeEvent: Identifiable, Codable, Hashable {
    let id: Int
    let type: String?
    let summary: String?
    let description: String?
    let happenedAt: String?
    let emotion: String?
    let costs: Double?
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case id, type, summary, description
        case happenedAt = "happened_at"
        case emotion, costs, currency
    }
}

struct ContactLoan: Identifiable, Codable, Hashable {
    let id: Int
    let direction: String
    let name: String?
    let description: String?
    let amount: Double?
    let currency: String?
    let loanedAt: String?
    let settled: Bool
    let settledAt: String?

    enum CodingKeys: String, CodingKey {
        case id, direction, name, description, amount, currency
        case loanedAt = "loaned_at"
        case settled
        case settledAt = "settled_at"
    }
}

struct ContactReminder: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let day: Int?
    let month: Int?
    let year: Int?
    let type: String?
    let frequencyNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id, label, day, month, year, type
        case frequencyNumber = "frequency_number"
    }
}

struct ContactMoodEvent: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let hexColor: String?
    let note: String?
    let hoursSlept: Double?
    let ratedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, label
        case hexColor = "hex_color"
        case note
        case hoursSlept = "hours_slept"
        case ratedAt = "rated_at"
    }
}

struct ContactLifeMetric: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
}

struct ContactDocument: Identifiable, Codable, Hashable {
    let id: Int
    let name: String?
    let mimeType: String?
    let type: String?
    let size: Int?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case mimeType = "mime_type"
        case type, size, url
    }
}

struct ContactPost: Identifiable, Codable, Hashable {
    let id: Int
    let title: String?
    let excerpt: String?
    let writtenAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, excerpt
        case writtenAt = "written_at"
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
