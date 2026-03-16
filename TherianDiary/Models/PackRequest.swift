import Foundation
import FirebaseFirestore

// MARK: - PackRequestStatus

enum PackRequestStatus: String, Codable {
    case pending  = "pending"
    case accepted = "accepted"
    case declined = "declined"
}

// MARK: - PackRequest

struct PackRequest: Identifiable, Equatable {
    let requestId: String
    let fromUserId: String
    let toUserId: String
    var status: PackRequestStatus
    var createdAt: Date

    var id: String { requestId }

    // MARK: Firestore dictionary
    var firestoreData: [String: Any] {
        [
            "requestId": requestId,
            "fromUserId": fromUserId,
            "toUserId": toUserId,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
    }

    // MARK: Init from Firestore
    init?(document: [String: Any]) {
        guard
            let requestId  = document["requestId"]  as? String,
            let fromUserId = document["fromUserId"] as? String,
            let toUserId   = document["toUserId"]   as? String,
            let statusRaw  = document["status"]     as? String,
            let status     = PackRequestStatus(rawValue: statusRaw)
        else { return nil }

        self.requestId  = requestId
        self.fromUserId = fromUserId
        self.toUserId   = toUserId
        self.status     = status
        self.createdAt  = (document["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }

    init(requestId: String = UUID().uuidString,
         fromUserId: String,
         toUserId: String,
         status: PackRequestStatus = .pending,
         createdAt: Date = Date()) {
        self.requestId  = requestId
        self.fromUserId = fromUserId
        self.toUserId   = toUserId
        self.status     = status
        self.createdAt  = createdAt
    }
}
