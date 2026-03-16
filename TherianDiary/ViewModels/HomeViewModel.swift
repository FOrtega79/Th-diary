import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var latestShift: Shift?
    @Published var streak: Int = 0
    @Published var totalShifts: Int = 0
    @Published var isLoading = false
    @Published var showLogShift = false

    private let firestore = FirestoreService.shared

    func loadDashboard(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        async let statsTask   = firestore.fetchStats(for: userId)
        async let latestTask  = firestore.fetchLatestShift(for: userId)

        do {
            let (stats, latest) = try await (statsTask, latestTask)
            streak      = stats.streak
            totalShifts = stats.total
            latestShift = latest
        } catch {
            print("HomeViewModel load error: \(error.localizedDescription)")
        }
    }

    func greetingText(for username: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning, \(username) 🌿"
        case 12..<17: return "Good afternoon, \(username) ☀️"
        case 17..<21: return "Good evening, \(username) 🌙"
        default:      return "Night, \(username) 🌑"
        }
    }
}
