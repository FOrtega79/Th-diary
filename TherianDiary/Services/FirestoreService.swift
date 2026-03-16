import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirestoreService

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Collections
    private var usersCollection: CollectionReference { db.collection("users") }
    private var shiftsCollection: CollectionReference { db.collection("shifts") }
    private var packRequestsCollection: CollectionReference { db.collection("packRequests") }

    // MARK: - User CRUD

    func createUser(_ user: TherianUser) async throws {
        try await usersCollection.document(user.uid).setData(user.firestoreData)
    }

    func fetchUser(uid: String) async throws -> TherianUser? {
        let snapshot = try await usersCollection.document(uid).getDocument()
        guard let data = snapshot.data() else { return nil }
        return TherianUser(document: data)
    }

    func updateUser(_ user: TherianUser) async throws {
        try await usersCollection.document(user.uid).setData(user.firestoreData, merge: true)
    }

    func updateUserField(uid: String, field: String, value: Any) async throws {
        try await usersCollection.document(uid).updateData([field: value])
    }

    func isUsernameTaken(_ username: String) async throws -> Bool {
        let snapshot = try await usersCollection
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    func searchUser(byUsername username: String) async throws -> TherianUser? {
        let snapshot = try await usersCollection
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        return TherianUser(document: doc.data())
    }

    func fetchPackMembers(uids: [String]) async throws -> [TherianUser] {
        guard !uids.isEmpty else { return [] }
        // Firestore 'in' queries support up to 30 elements; chunk if needed
        let chunks = uids.chunked(into: 10)
        var members: [TherianUser] = []
        for chunk in chunks {
            let snapshot = try await usersCollection
                .whereField("uid", in: chunk)
                .getDocuments()
            members += snapshot.documents.compactMap { TherianUser(document: $0.data()) }
        }
        return members
    }

    // MARK: - Shift CRUD

    func saveShift(_ shift: Shift) async throws {
        try await shiftsCollection.document(shift.shiftId).setData(shift.firestoreData)
    }

    func fetchShifts(for userId: String, limit: Int = 50) async throws -> [Shift] {
        let snapshot = try await shiftsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { Shift(document: $0.data()) }
    }

    func fetchLatestShift(for userId: String) async throws -> Shift? {
        let snapshot = try await shiftsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap { Shift(document: $0.data()) }
    }

    func deleteShift(shiftId: String) async throws {
        try await shiftsCollection.document(shiftId).delete()
    }

    // MARK: - Streak & Stats

    /// Returns (streak, totalShifts)
    func fetchStats(for userId: String) async throws -> (streak: Int, total: Int) {
        let shifts = try await fetchShifts(for: userId, limit: 365)
        let total = shifts.count
        let streak = calculateStreak(from: shifts)
        return (streak, total)
    }

    private func calculateStreak(from shifts: [Shift]) -> Int {
        guard !shifts.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sortedDates = shifts
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if date < checkDate {
                break
            }
        }
        return streak
    }

    // MARK: - Pack Requests

    func sendPackRequest(from fromUserId: String, to toUserId: String) async throws {
        // Check no existing pending request
        let existing = try await packRequestsCollection
            .whereField("fromUserId", isEqualTo: fromUserId)
            .whereField("toUserId", isEqualTo: toUserId)
            .whereField("status", isEqualTo: "pending")
            .limit(to: 1)
            .getDocuments()
        guard existing.documents.isEmpty else { return }

        let request = PackRequest(fromUserId: fromUserId, toUserId: toUserId)
        try await packRequestsCollection.document(request.requestId).setData(request.firestoreData)
    }

    func fetchIncomingPackRequests(for userId: String) async throws -> [PackRequest] {
        let snapshot = try await packRequestsCollection
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        return snapshot.documents.compactMap { PackRequest(document: $0.data()) }
    }

    func respondToPackRequest(requestId: String,
                               fromUserId: String,
                               toUserId: String,
                               accept: Bool) async throws {
        let status = accept ? PackRequestStatus.accepted : PackRequestStatus.declined
        try await packRequestsCollection.document(requestId)
            .updateData(["status": status.rawValue])

        if accept {
            // Mutually add both users to each other's pack
            let batch = db.batch()
            let fromRef = usersCollection.document(fromUserId)
            let toRef   = usersCollection.document(toUserId)
            batch.updateData(["packMembers": FieldValue.arrayUnion([toUserId])], forDocument: fromRef)
            batch.updateData(["packMembers": FieldValue.arrayUnion([fromUserId])], forDocument: toRef)
            try await batch.commit()
        }
    }

    func removePackMember(userId: String, memberToRemove: String) async throws {
        let batch = db.batch()
        let userRef   = usersCollection.document(userId)
        let memberRef = usersCollection.document(memberToRemove)
        batch.updateData(["packMembers": FieldValue.arrayRemove([memberToRemove])], forDocument: userRef)
        batch.updateData(["packMembers": FieldValue.arrayRemove([userId])], forDocument: memberRef)
        try await batch.commit()
    }
}

// MARK: - Array chunking helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
