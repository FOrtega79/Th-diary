import Foundation
import FirebaseFirestore

// MARK: - ShiftType

enum ShiftType: String, Codable, CaseIterable, Identifiable {
    case mental  = "Mental"
    case phantom = "Phantom"
    case dream   = "Dream"
    case cameo   = "Cameo"
    case astral  = "Astral"
    case sensory = "Sensory"
    case aura    = "Aura"
    case bi      = "Bi-location"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .mental:  return "brain.head.profile"
        case .phantom: return "waveform.path.ecg.rectangle"
        case .dream:   return "moon.stars"
        case .cameo:   return "theatermasks"
        case .astral:  return "sparkles"
        case .sensory: return "eye.fill"
        case .aura:    return "rays"
        case .bi:      return "arrow.triangle.branch"
        }
    }

    var description: String {
        switch self {
        case .mental:  return "A mental shift in thinking or awareness"
        case .phantom: return "Phantom limb sensations (tail, wings, etc.)"
        case .dream:   return "Theriotype appeared in a dream"
        case .cameo:   return "Brief shift into a non-primary theriotype"
        case .astral:  return "Spiritual or astral projection experience"
        case .sensory: return "Heightened or altered senses"
        case .aura:    return "Energy or aura-based shift"
        case .bi:      return "Sense of being in two places or forms"
        }
    }
}

// MARK: - Shift

struct Shift: Identifiable, Equatable {
    let shiftId: String
    let userId: String
    var type: ShiftType
    var intensity: Int          // 1 – 10
    var tags: [String]
    var notes: String
    var date: Date

    var id: String { shiftId }

    // MARK: Computed
    var intensityLabel: String {
        switch intensity {
        case 1...3:  return "Mild"
        case 4...6:  return "Moderate"
        case 7...9:  return "Strong"
        case 10:     return "Overwhelming"
        default:     return "Unknown"
        }
    }

    // MARK: Firestore dictionary
    var firestoreData: [String: Any] {
        [
            "shiftId": shiftId,
            "userId": userId,
            "type": type.rawValue,
            "intensity": intensity,
            "tags": tags,
            "notes": notes,
            "date": Timestamp(date: date)
        ]
    }

    // MARK: Init from Firestore
    init?(document: [String: Any]) {
        guard
            let shiftId = document["shiftId"] as? String,
            let userId  = document["userId"]  as? String,
            let typeRaw = document["type"]    as? String,
            let type    = ShiftType(rawValue: typeRaw),
            let intensity = document["intensity"] as? Int
        else { return nil }

        self.shiftId   = shiftId
        self.userId    = userId
        self.type      = type
        self.intensity = intensity
        self.tags      = document["tags"]  as? [String] ?? []
        self.notes     = document["notes"] as? String ?? ""
        self.date      = (document["date"] as? Timestamp)?.dateValue() ?? Date()
    }

    init(shiftId: String = UUID().uuidString,
         userId: String,
         type: ShiftType = .mental,
         intensity: Int = 5,
         tags: [String] = [],
         notes: String = "",
         date: Date = Date()) {
        self.shiftId   = shiftId
        self.userId    = userId
        self.type      = type
        self.intensity = intensity
        self.tags      = tags
        self.notes     = notes
        self.date      = date
    }
}

// MARK: - Common Tags
extension Shift {
    static let commonTags = [
        "Nature", "Full Moon", "Music", "Running", "Meditation",
        "Stress", "Crowd", "Rain", "Night", "Solitude",
        "Social Media", "Forest", "Water", "Wind", "Animals"
    ]
}
