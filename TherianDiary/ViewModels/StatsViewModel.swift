import Foundation
import SwiftUI

// MARK: - ShiftTypeCount (for chart data)

struct ShiftTypeCount: Identifiable {
    let id = UUID()
    let type: ShiftType
    let count: Int
    var percentage: Double = 0
}

@MainActor
final class StatsViewModel: ObservableObject {

    @Published var allShifts: [Shift] = []
    @Published var streak: Int = 0
    @Published var totalShifts: Int = 0
    @Published var averageIntensity: Double = 0
    @Published var typeBreakdown: [ShiftTypeCount] = []
    @Published var topTriggers: [(String, Int)] = []

    @Published var isLoading = false

    // Pie chart ad-unlock
    @Published var chartUnlockExpiry: Date?

    var isChartUnlocked: Bool {
        guard let expiry = chartUnlockExpiry else { return false }
        return expiry > Date()
    }

    private let firestore = FirestoreService.shared

    // MARK: - Load

    func loadStats(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let shifts = try await firestore.fetchShifts(for: userId, limit: 365)
            allShifts = shifts
            computeStats(shifts: shifts)
        } catch {
            print("StatsViewModel load error: \(error.localizedDescription)")
        }
    }

    private func computeStats(shifts: [Shift]) {
        totalShifts = shifts.count
        streak = calculateStreak(from: shifts)

        if !shifts.isEmpty {
            averageIntensity = Double(shifts.map(\.intensity).reduce(0, +)) / Double(shifts.count)
        }

        // Type breakdown
        var counts: [ShiftType: Int] = [:]
        for shift in shifts {
            counts[shift.type, default: 0] += 1
        }
        let total = max(shifts.count, 1)
        typeBreakdown = counts.map { type, count in
            ShiftTypeCount(type: type, count: count, percentage: Double(count) / Double(total) * 100)
        }.sorted { $0.count > $1.count }

        // Top triggers (tags)
        var tagCounts: [String: Int] = [:]
        for shift in shifts {
            shift.tags.forEach { tagCounts[$0, default: 0] += 1 }
        }
        topTriggers = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
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

    // MARK: - Ad unlock for chart

    func unlockChartForDay() {
        chartUnlockExpiry = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
    }

    // MARK: - Last 7 days for mini chart

    func shiftsPerDay(lastDays: Int = 7) -> [(Date, Int)] {
        let calendar = Calendar.current
        return (0..<lastDays).map { offset -> (Date, Int) in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date())!
            let day  = calendar.startOfDay(for: date)
            let count = allShifts.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
            return (day, count)
        }.reversed()
    }
}
