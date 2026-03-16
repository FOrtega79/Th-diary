import XCTest
@testable import TherianDiary

final class TherianDiaryTests: XCTestCase {

    // MARK: - Model Tests

    func testShiftCreation() {
        let shift = Shift(userId: "test-uid", type: .mental, intensity: 7)
        XCTAssertEqual(shift.type, .mental)
        XCTAssertEqual(shift.intensity, 7)
        XCTAssertFalse(shift.shiftId.isEmpty)
    }

    func testShiftIntensityLabel() {
        XCTAssertEqual(Shift(userId: "u", intensity: 2).intensityLabel, "Mild")
        XCTAssertEqual(Shift(userId: "u", intensity: 5).intensityLabel, "Moderate")
        XCTAssertEqual(Shift(userId: "u", intensity: 8).intensityLabel, "Strong")
        XCTAssertEqual(Shift(userId: "u", intensity: 10).intensityLabel, "Overwhelming")
    }

    func testUserPackLimit() {
        let freeUser    = TherianUser(uid: "1", username: "wolf", primaryTheriotype: "Wolf", isPremium: false)
        let premiumUser = TherianUser(uid: "2", username: "fox",  primaryTheriotype: "Fox",  isPremium: true)
        XCTAssertEqual(freeUser.maxPackSize,    5)
        XCTAssertEqual(premiumUser.maxPackSize, 20)
    }

    func testPackRequestStatusDecoding() {
        let raw = PackRequestStatus(rawValue: "pending")
        XCTAssertEqual(raw, .pending)
    }

    // MARK: - Theriotype Tests

    func testTheriotypeEmojis() {
        XCTAssertEqual(Theriotype.wolf.emoji, "🐺")
        XCTAssertEqual(Theriotype.fox.emoji,  "🦊")
    }

    func testShiftTypeIcons() {
        XCTAssertFalse(ShiftType.mental.icon.isEmpty)
        XCTAssertFalse(ShiftType.phantom.icon.isEmpty)
    }

    // MARK: - ViewModel Unit Tests (no Firebase)

    @MainActor
    func testLogShiftViewModelReset() {
        let vm = LogShiftViewModel()
        vm.selectedType = .dream
        vm.intensity = 9
        vm.selectedTags = ["Forest", "Rain"]
        vm.notes = "Test note"

        vm.reset()

        XCTAssertEqual(vm.selectedType, .mental)
        XCTAssertEqual(vm.intensity, 5)
        XCTAssertTrue(vm.selectedTags.isEmpty)
        XCTAssertTrue(vm.notes.isEmpty)
    }

    @MainActor
    func testLogShiftViewModelToggleTag() {
        let vm = LogShiftViewModel()
        vm.toggleTag("Forest")
        XCTAssertTrue(vm.selectedTags.contains("Forest"))
        vm.toggleTag("Forest")
        XCTAssertFalse(vm.selectedTags.contains("Forest"))
    }

    @MainActor
    func testStatsViewModelStreakCalculation() {
        let vm = StatsViewModel()
        // Indirectly test via shiftsPerDay being empty with no shifts loaded
        let days = vm.shiftsPerDay(lastDays: 7)
        XCTAssertEqual(days.count, 7)
    }
}
