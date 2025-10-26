import Foundation

enum OverlayDisplayPreference: Codable {
    case primary
    case active
    case display(id: String, name: String?)

    private enum CodingKeys: String, CodingKey {
        case type, id, name
    }

    private enum PreferenceType: String, Codable {
        case primary
        case active
        case display
    }

    var identifier: String {
        switch self {
        case .primary:
            return "primary"
        case .active:
            return "active"
        case .display(let id, _):
            return "display-\(id)"
        }
    }

    var storedName: String? {
        if case let .display(_, name) = self {
            return name
        }
        return nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .primary:
            try container.encode(PreferenceType.primary, forKey: .type)
        case .active:
            try container.encode(PreferenceType.active, forKey: .type)
        case let .display(id, name):
            try container.encode(PreferenceType.display, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(name, forKey: .name)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PreferenceType.self, forKey: .type)
        switch type {
        case .primary:
            self = .primary
        case .active:
            self = .active
        case .display:
            let id = try container.decode(String.self, forKey: .id)
            let name = try container.decodeIfPresent(String.self, forKey: .name)
            self = .display(id: id, name: name)
        }
    }
}

extension OverlayDisplayPreference: Equatable {
    static func == (lhs: OverlayDisplayPreference, rhs: OverlayDisplayPreference) -> Bool {
        switch (lhs, rhs) {
        case (.primary, .primary), (.active, .active):
            return true
        case let (.display(idL, _), .display(idR, _)):
            return idL == idR
        default:
            return false
        }
    }
}

extension OverlayDisplayPreference: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .primary:
            hasher.combine("primary")
        case .active:
            hasher.combine("active")
        case .display(let id, _):
            hasher.combine("display")
            hasher.combine(id)
        }
    }
}

enum OverlayDisplayPreferenceStorage {
    private static let storageKey = "com.brycesmith.wuzzy.displayPreference"

    static func load(from defaults: UserDefaults) -> OverlayDisplayPreference? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(OverlayDisplayPreference.self, from: data)
    }

    static func store(preference: OverlayDisplayPreference, defaults: UserDefaults) {
        let data = try? JSONEncoder().encode(preference)
        defaults.set(data, forKey: storageKey)
    }
}

