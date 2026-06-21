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
    let genderId: Int?
    let pronounId: Int?
    let religionId: Int?
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
    let family: ContactFamily?
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
        case genderId = "gender_id"
        case pronounId = "pronoun_id"
        case religionId = "religion_id"
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
        case documents, posts, family
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
        genderId      = try? c.decodeIfPresent(Int.self, forKey: .genderId)
        pronounId     = try? c.decodeIfPresent(Int.self, forKey: .pronounId)
        religionId    = try? c.decodeIfPresent(Int.self, forKey: .religionId)
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
        family              = try? c.decodeIfPresent(ContactFamily.self,        forKey: .family)
    }

    /// Lightweight stub used to navigate to a related contact; the detail
    /// view fetches the full record by id on appear.
    init(stubId id: String, vaultId: String, name: String?, avatar: ContactAvatar?) {
        self.id = id
        self.vaultId = vaultId
        self.firstName = name
        self.lastName = nil; self.middleName = nil; self.nickname = nil; self.maidenName = nil
        self.prefix = nil; self.suffix = nil
        self.listed = true
        self.canBeDeleted = false
        self.avatar = avatar
        self.gender = nil; self.pronoun = nil; self.religion = nil; self.jobPosition = nil
        self.genderId = nil; self.pronounId = nil; self.religionId = nil
        self.company = nil
        self.contactInformations = nil; self.importantDates = nil; self.addresses = nil
        self.notes = nil; self.labels = nil; self.groups = nil; self.relationships = nil
        self.tasks = nil; self.calls = nil; self.pets = nil; self.goals = nil
        self.quickFacts = nil; self.timelineEvents = nil; self.loans = nil; self.reminders = nil
        self.moodTrackingEvents = nil; self.lifeMetrics = nil; self.documents = nil
        self.posts = nil; self.family = nil
        self.createdAt = nil; self.updatedAt = nil
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
    let typeId: Int?
    let label: String
    let type: String?
    let `protocol`: String?
    let data: String

    enum CodingKeys: String, CodingKey {
        case id
        case typeId = "type_id"
        case label, type, `protocol`, data
    }

    var callURL: URL? {
        guard let proto = `protocol`, !proto.isEmpty else { return nil }
        return URL(string: proto + data)
    }
}

struct ContactDate: Identifiable, Codable, Hashable {
    let id: Int
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
    let id: Int
    let name: String
    let type: String?
}

struct ContactRelationship: Identifiable, Codable, Hashable {
    let contactId: String
    let name: String?
    let avatar: ContactAvatar?
    let relationshipType: String?
    let relationshipTypeId: Int?
    let group: String?

    var id: String { "\(contactId)-\(relationshipType ?? "")" }

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case name, avatar, group
        case relationshipType = "relationship_type"
        case relationshipTypeId = "relationship_type_id"
    }
}

struct ContactTask: Identifiable, Codable, Hashable {
    let id: Int
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

struct ContactFamily: Codable, Hashable {
    let partners: [FamilyMember]
    let children: [FamilyMember]

    var isEmpty: Bool { partners.isEmpty && children.isEmpty }
}

struct FamilyMember: Identifiable, Codable, Hashable {
    let contactId: String
    let name: String?
    let avatar: ContactAvatar?
    let age: Int?

    var id: String { contactId }

    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case name, avatar, age
    }
}

struct ContactResponse: Codable {
    let data: [Contact]
    let meta: PageMeta?
}

struct PageMeta: Codable {
    let currentPage: Int?
    let lastPage: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case lastPage = "last_page"
    }
}

struct ContactPayload: Codable {
    var firstName: String
    var lastName: String
    var middleName: String
    var nickname: String
    var maidenName: String = ""
    var prefix: String
    var suffix: String
    var listed: Bool
    var genderId: Int?
    var pronounId: Int?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case middleName = "middle_name"
        case maidenName = "maiden_name"
        case nickname, prefix, suffix, listed
        case genderId = "gender_id"
        case pronounId = "pronoun_id"
    }
}

// MARK: - Module write payloads
//
// Property names are camelCase; MonicaAPI encodes with
// `.convertToSnakeCase`, and nil optionals are omitted by the synthesized
// Encodable, so they map cleanly onto the Laravel module services.

struct NotePayload: Encodable {
    var title: String?
    var body: String
    var emotionId: Int?
}

struct TaskPayload: Encodable {
    var label: String
    var description: String?
    var dueAt: String?
}

struct CallPayload: Encodable {
    var calledAt: String        // "yyyy-MM-dd"
    var type: String            // "audio" | "video"
    var whoInitiated: String    // "me" | "contact"
    var duration: Int?
    var description: String?
    var answered: Bool?
}

struct ReminderPayload: Encodable {
    var label: String
    var day: Int?
    var month: Int?
    var year: Int?
    var type: String            // one_time | recurring_day | recurring_month | recurring_year
    var frequencyNumber: Int?
}

struct ImportantDatePayload: Encodable {
    var label: String
    var day: Int?
    var month: Int?
    var year: Int?
}

struct ContactInformationPayload: Encodable {
    var contactInformationTypeId: Int
    var data: String
}

struct AddressPayload: Encodable {
    var line1: String?
    var line2: String?
    var city: String?
    var province: String?
    var postalCode: String?
    var country: String?
    var isPastAddress: Bool
}

// MARK: - Reference data (picker lookups)

struct ReferenceData: Codable {
    let contactInformationTypes: [ReferenceType]
    let addressTypes: [ReferenceType]
    let importantDateTypes: [ReferenceType]
    let genders: [ReferenceType]
    let pronouns: [ReferenceType]
    let religions: [ReferenceType]
    let petCategories: [ReferenceType]
    let currencies: [CurrencyRef]
    let moodParameters: [MoodParameterRef]
    let quickFactTemplates: [ReferenceType]
    let relationshipTypes: [RelationshipTypeRef]
    let groupTypes: [GroupTypeRef]
    let lifeEventCategories: [LifeEventCategoryRef]
    let labels: [ContactLabel]
    let groups: [ContactGroup]
    let companies: [ContactCompany]
    let meContactId: String?

    enum CodingKeys: String, CodingKey {
        case contactInformationTypes = "contact_information_types"
        case addressTypes = "address_types"
        case importantDateTypes = "important_date_types"
        case genders, pronouns, religions
        case petCategories = "pet_categories"
        case currencies
        case moodParameters = "mood_parameters"
        case quickFactTemplates = "quick_fact_templates"
        case relationshipTypes = "relationship_types"
        case groupTypes = "group_types"
        case lifeEventCategories = "life_event_categories"
        case labels, groups, companies
        case meContactId = "me_contact_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func arr<T: Decodable>(_ k: CodingKeys, _ t: T.Type) -> [T] {
            ((try? c.decodeIfPresent([T].self, forKey: k)) ?? []) ?? []
        }
        contactInformationTypes = arr(.contactInformationTypes, ReferenceType.self)
        addressTypes = arr(.addressTypes, ReferenceType.self)
        importantDateTypes = arr(.importantDateTypes, ReferenceType.self)
        genders = arr(.genders, ReferenceType.self)
        pronouns = arr(.pronouns, ReferenceType.self)
        religions = arr(.religions, ReferenceType.self)
        petCategories = arr(.petCategories, ReferenceType.self)
        currencies = arr(.currencies, CurrencyRef.self)
        moodParameters = arr(.moodParameters, MoodParameterRef.self)
        quickFactTemplates = arr(.quickFactTemplates, ReferenceType.self)
        relationshipTypes = arr(.relationshipTypes, RelationshipTypeRef.self)
        groupTypes = arr(.groupTypes, GroupTypeRef.self)
        lifeEventCategories = arr(.lifeEventCategories, LifeEventCategoryRef.self)
        labels = arr(.labels, ContactLabel.self)
        groups = arr(.groups, ContactGroup.self)
        companies = arr(.companies, ContactCompany.self)
        meContactId = try? c.decodeIfPresent(String.self, forKey: .meContactId)
    }
}

struct CurrencyRef: Identifiable, Codable, Hashable {
    let id: Int
    let code: String
}

struct MoodParameterRef: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let hexColor: String?

    enum CodingKeys: String, CodingKey {
        case id, label
        case hexColor = "hex_color"
    }
}

struct RelationshipTypeRef: Identifiable, Codable, Hashable {
    let id: Int
    let name: String?
    let reverseName: String?
    let group: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case reverseName = "reverse_name"
        case group
    }

    var displayName: String { name ?? "Relationship" }
}

struct GroupRoleRef: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
}

struct GroupTypeRef: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let roles: [GroupRoleRef]
}

struct LifeEventTypeRef: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
}

struct LifeEventCategoryRef: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let types: [LifeEventTypeRef]
}

struct ReferenceType: Identifiable, Codable, Hashable {
    let id: Int
    let name: String?
    let label: String?
    let type: String?
    let `protocol`: String?

    var displayName: String { name ?? label ?? "—" }
}

struct ReferenceResponse: Codable {
    let data: ReferenceData
}


// MARK: - Additional module write payloads

struct PetPayload: Encodable {
    var petCategoryId: Int
    var name: String?
}

struct GoalPayload: Encodable {
    var name: String
}

struct QuickFactPayload: Encodable {
    var vaultQuickFactsTemplateId: Int?
    var content: String
}

struct MoodPayload: Encodable {
    var moodTrackingParameterId: Int
    var ratedAt: String
    var note: String?
    var numberOfHoursSlept: Int?
}

struct LoanPayload: Encodable {
    var type: String
    var name: String
    var description: String?
    var amountLent: Int?
    var currencyId: Int?
    var loanedAt: String?
    var loanerIds: [String]
    var loaneeIds: [String]
}

struct RelationshipPayload: Encodable {
    var relationshipTypeId: Int
    var otherContactId: String
}

struct LabelPayload: Encodable {
    var labelId: Int?
    var name: String?
}

struct GroupPayload: Encodable {
    var groupId: Int?
    var name: String?
    var groupTypeId: Int?
}

struct ReligionPayload: Encodable {
    var religionId: Int?
}

struct JobPayload: Encodable {
    var jobPosition: String?
    var companyId: Int?
    var companyName: String?
}

struct LifeEventPayload: Encodable {
    var lifeEventTypeId: Int
    var summary: String?
    var description: String?
    var happenedAt: String
    var costs: Int?
    var currencyId: Int?
}


// MARK: - Vault dashboard models

struct DashboardContact: Identifiable, Codable, Hashable {
    let id: String
    let name: String?
    let avatar: ContactAvatar?
}

struct VaultTask: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let description: String?
    let completed: Bool
    let dueAt: String?
    let contact: DashboardContact

    enum CodingKeys: String, CodingKey {
        case id, label, description, completed
        case dueAt = "due_at"
        case contact
    }
}

struct VaultReminderItem: Identifiable, Codable, Hashable {
    let id: Int
    let label: String?
    let day: Int?
    let month: Int?
    let year: Int?
    let type: String?
    let contact: DashboardContact

    var dateText: String {
        [month.map { Calendar.current.monthSymbols[$0 - 1] }, day.map(String.init), year.map(String.init)]
            .compactMap { $0 }.joined(separator: " ")
    }
}

struct VaultPostItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String?
    let writtenAt: String?
    let journal: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case writtenAt = "written_at"
        case journal
    }
}

struct DataResponse<T: Codable>: Codable {
    let data: [T]
}
