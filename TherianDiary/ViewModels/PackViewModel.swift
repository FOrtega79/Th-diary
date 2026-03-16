import Foundation
import SwiftUI

@MainActor
final class PackViewModel: ObservableObject {

    @Published var packMembers: [TherianUser] = []
    @Published var incomingRequests: [PackRequest] = []
    @Published var searchResults: TherianUser?
    @Published var searchQuery: String = ""

    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?

    // Ad-unlock state: temporary extra slot active until this date
    @Published var temporarySlotExpiry: Date?

    private let firestore = FirestoreService.shared

    var hasTemporarySlot: Bool {
        guard let expiry = temporarySlotExpiry else { return false }
        return expiry > Date()
    }

    // MARK: - Load

    func loadPack(for user: TherianUser) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let membersTask  = firestore.fetchPackMembers(uids: user.packMembers)
            async let requestsTask = firestore.fetchIncomingPackRequests(for: user.uid)
            let (members, requests) = try await (membersTask, requestsTask)
            packMembers = members
            incomingRequests = requests
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search

    func searchUser() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { searchResults = nil; return }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await firestore.searchUser(byUsername: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Send Howl (Friend Request)

    func sendHowl(from userId: String, to targetUser: TherianUser) async {
        do {
            try await firestore.sendPackRequest(from: userId, to: targetUser.uid)
            HapticsManager.shared.mediumTap()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Respond to Request

    func accept(request: PackRequest) async {
        do {
            try await firestore.respondToPackRequest(
                requestId: request.requestId,
                fromUserId: request.fromUserId,
                toUserId: request.toUserId,
                accept: true
            )
            HapticsManager.shared.heavySuccess()
            incomingRequests.removeAll { $0.requestId == request.requestId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(request: PackRequest) async {
        do {
            try await firestore.respondToPackRequest(
                requestId: request.requestId,
                fromUserId: request.fromUserId,
                toUserId: request.toUserId,
                accept: false
            )
            incomingRequests.removeAll { $0.requestId == request.requestId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Remove Member

    func removeFromPack(userId: String, memberId: String) async {
        do {
            try await firestore.removePackMember(userId: userId, memberToRemove: memberId)
            packMembers.removeAll { $0.uid == memberId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Temporary slot (after rewarded ad)

    func unlockTemporarySlot() {
        temporarySlotExpiry = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
    }
}
