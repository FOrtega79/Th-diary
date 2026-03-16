import Foundation
import SwiftUI

@MainActor
final class LogShiftViewModel: ObservableObject {

    // Form state
    @Published var selectedType: ShiftType = .mental
    @Published var intensity: Double = 5
    @Published var selectedTags: Set<String> = []
    @Published var notes: String = ""

    // UI state
    @Published var isLoading = false
    @Published var didSave = false
    @Published var errorMessage: String?
    @Published var showConfetti = false

    private let firestore = FirestoreService.shared

    // MARK: - Save

    func saveShift(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        let shift = Shift(
            userId: userId,
            type: selectedType,
            intensity: Int(intensity),
            tags: Array(selectedTags),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try await firestore.saveShift(shift)
            HapticsManager.shared.mediumTap()
            showConfetti = true
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }

    // MARK: - Toggle Tag

    func toggleTag(_ tag: String) {
        HapticsManager.shared.lightTap()
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    // MARK: - Reset

    func reset() {
        selectedType = .mental
        intensity = 5
        selectedTags = []
        notes = ""
        didSave = false
        showConfetti = false
        errorMessage = nil
    }
}
