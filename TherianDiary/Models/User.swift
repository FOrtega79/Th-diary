import Foundation
import FirebaseFirestore

// MARK: - Theriotype

enum Theriotype: String, Codable, CaseIterable, Identifiable {
    case wolf       = "Wolf"
    case fox        = "Fox"
    case cat        = "Cat"
    case dog        = "Dog"
    case deer       = "Deer"
    case dragon     = "Dragon"
    case eagle      = "Eagle"
    case bear       = "Bear"
    case rabbit     = "Rabbit"
    case horse      = "Horse"
    case raven      = "Raven"
    case lion       = "Lion"
    case tiger      = "Tiger"
    case owl        = "Owl"
    case snake      = "Snake"
    case other      = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .wolf:   return "🐺"
        case .fox:    return "🦊"
        case .cat:    return "🐱"
        case .dog:    return "🐶"
        case .deer:   return "🦌"
        case .dragon: return "🐉"
        case .eagle:  return "🦅"
        case .bear:   return "🐻"
        case .rabbit: return "🐰"
        case .horse:  return "🐴"
        case .raven:  return "🦅"
        case .lion:   return "🦁"
        case .tiger:  return "🐯"
        case .owl:    return "🦉"
        case .snake:  return "🐍"
        case .other:  return "✨"
        }
    }
}

// MARK: - TherianUser

struct TherianUser: Codable, Identifiable, Equatable {
    let uid: String
    var username: String
    var primaryTheriotype: String
    var secondaryTheriotype: String?
    var bio: String
    var profileImageUrl: String
    var isPremium: Bool
    var packMembers: [String]
    var createdAt: Date

    var id: String { uid }

    // MARK: Computed
    var maxPackSize: Int { isPremium ? 20 : 5 }
    var hasReachedPackLimit: Bool { packMembers.count >= maxPackSize }

    // MARK: Firestore dictionary
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "uid": uid,
            "username": username,
            "primaryTheriotype": primaryTheriotype,
            "bio": bio,
            "profileImageUrl": profileImageUrl,
            "isPremium": isPremium,
            "packMembers": packMembers,
            "createdAt": Timestamp(date: createdAt)
        ]
        if let secondary = secondaryTheriotype {
            data["secondaryTheriotype"] = secondary
        }
        return data
    }

    // MARK: Init from Firestore
    init?(document: [String: Any]) {
        guard
            let uid = document["uid"] as? String,
            let username = document["username"] as? String,
            let primaryTheriotype = document["primaryTheriotype"] as? String
        else { return nil }

        self.uid = uid
        self.username = username
        self.primaryTheriotype = primaryTheriotype
        self.secondaryTheriotype = document["secondaryTheriotype"] as? String
        self.bio = document["bio"] as? String ?? ""
        self.profileImageUrl = document["profileImageUrl"] as? String ?? ""
        self.isPremium = document["isPremium"] as? Bool ?? false
        self.packMembers = document["packMembers"] as? [String] ?? []
        self.createdAt = (document["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }

    init(uid: String,
         username: String,
         primaryTheriotype: String,
         secondaryTheriotype: String? = nil,
         bio: String = "",
         profileImageUrl: String = "",
         isPremium: Bool = false,
         packMembers: [String] = [],
         createdAt: Date = Date()) {
        self.uid = uid
        self.username = username
        self.primaryTheriotype = primaryTheriotype
        self.secondaryTheriotype = secondaryTheriotype
        self.bio = bio
        self.profileImageUrl = profileImageUrl
        self.isPremium = isPremium
        self.packMembers = packMembers
        self.createdAt = createdAt
    }
}
