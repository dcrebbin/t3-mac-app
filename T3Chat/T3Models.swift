import Foundation

// The "meta" field in the last example is an object with a "values" dictionary.
struct ConversationHistoryMeta: Codable {
    let values: [String: [String]]?
}

// The "json" field can be either a dictionary or an array, depending on the response.
// We'll use an enum to handle both cases.
enum ConversationHistoryJson: Codable {
    case dict([String: [[[AnyCodable]]]])
    case array([AnyCodable])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dict = try? container.decode([String: [[[AnyCodable]]]].self) {
            self = .dict(dict)
        } else if let array = try? container.decode([AnyCodable].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(
                ConversationHistoryJson.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected dictionary or array for ConversationHistoryJson"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .dict(let dict):
            try container.encode(dict)
        case .array(let array):
            try container.encode(array)
        }
    }
}

// Top-level ConversationHistory struct
struct ConversationHistory: Codable {
    let json: ConversationHistoryJson
    let meta: ConversationHistoryMeta?
}

// Thread and message models as seen in the example
struct ConversationThread: Codable {
    let id: String
    let model: String
    let title: String
    let status: String
    let created_at: String
    let updated_at: String?
    let last_message_at: String?
    let user_edited_title: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, model, title, status, created_at, updated_at, last_message_at, user_edited_title
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle AnyCodable wrapped values
        if let idValue = try? container.decode(AnyCodable.self, forKey: .id),
           let id = idValue.value as? String {
            self.id = id
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        
        if let modelValue = try? container.decode(AnyCodable.self, forKey: .model),
           let model = modelValue.value as? String {
            self.model = model
        } else {
            model = try container.decode(String.self, forKey: .model)
        }
        
        if let titleValue = try? container.decode(AnyCodable.self, forKey: .title),
           let title = titleValue.value as? String {
            self.title = title
        } else {
            title = try container.decode(String.self, forKey: .title)
        }
        
        if let statusValue = try? container.decode(AnyCodable.self, forKey: .status),
           let status = statusValue.value as? String {
            self.status = status
        } else {
            status = try container.decode(String.self, forKey: .status)
        }
        
        if let createdValue = try? container.decode(AnyCodable.self, forKey: .created_at),
           let created = createdValue.value as? String {
            self.created_at = created
        } else {
            created_at = try container.decode(String.self, forKey: .created_at)
        }
        
        if let updatedValue = try? container.decode(AnyCodable.self, forKey: .updated_at),
           let updated = updatedValue.value as? String {
            self.updated_at = updated
        } else {
            updated_at = try container.decodeIfPresent(String.self, forKey: .updated_at)
        }
        
        if let lastMessageValue = try? container.decode(AnyCodable.self, forKey: .last_message_at),
           let lastMessage = lastMessageValue.value as? String {
            self.last_message_at = lastMessage
        } else {
            last_message_at = try container.decodeIfPresent(String.self, forKey: .last_message_at)
        }
        
        if let editedValue = try? container.decode(AnyCodable.self, forKey: .user_edited_title),
           let edited = editedValue.value as? Bool {
            self.user_edited_title = edited
        } else {
            user_edited_title = try container.decodeIfPresent(Bool.self, forKey: .user_edited_title)
        }
    }
}

struct ConversationMessage: Codable {
    let id: String
    let role: String
    let model: String
    let status: String
    let content: String
    let threadId: String?
    let created_at: String?
    let modelParams: [String: String]?
    let attachments: [AnyCodable]?
    let providerMetadata: ProviderMetadata?
    let errorReason: String?
    
    enum CodingKeys: String, CodingKey {
        case id, role, model, status, content, threadId, created_at, modelParams, attachments, providerMetadata, errorReason
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        role = try container.decode(String.self, forKey: .role)
        model = try container.decode(String.self, forKey: .model)
        status = try container.decode(String.self, forKey: .status)
        content = try container.decode(String.self, forKey: .content)
        threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        created_at = try container.decodeIfPresent(String.self, forKey: .created_at)
        modelParams = try container.decodeIfPresent([String: String].self, forKey: .modelParams)
        attachments = try container.decodeIfPresent([AnyCodable].self, forKey: .attachments)
        providerMetadata = try container.decodeIfPresent(ProviderMetadata.self, forKey: .providerMetadata)
        errorReason = try container.decodeIfPresent(String.self, forKey: .errorReason)
    }
}

struct ProviderMetadata: Codable {
    let google: GoogleMetadata?
}

struct GoogleMetadata: Codable {
    let safetyRatings: [AnyCodable]?
    let groundingMetadata: [AnyCodable]?
}

// Helper type to decode arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let dictVal as [String: AnyCodable]:
            try container.encode(dictVal)
        case let arrayVal as [AnyCodable]:
            try container.encode(arrayVal)
        case _ as NSNull:
            try container.encodeNil()
        default:
            let context = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// Helper for decoding the sequence of objects
struct ConversationHistorySequence: Codable {
    let histories: [ConversationHistory]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var histories: [ConversationHistory] = []
        
        while !container.isAtEnd {
            if let history = try? container.decode(ConversationHistory.self) {
                histories.append(history)
            }
        }
        
        self.histories = histories
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for history in histories {
            try container.encode(history)
        }
    }
}