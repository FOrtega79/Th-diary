import UIKit

/// Centralised haptic feedback manager.
/// Use the shared singleton everywhere to maintain consistent feedback.
final class HapticsManager {
    static let shared = HapticsManager()
    private init() {}

    // MARK: - Generators (lazy)
    private lazy var lightGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()

    private lazy var mediumGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.prepare()
        return g
    }()

    private lazy var heavyGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        return g
    }()

    private lazy var notificationGenerator: UINotificationFeedbackGenerator = {
        let g = UINotificationFeedbackGenerator()
        g.prepare()
        return g
    }()

    // MARK: - Public API

    /// Light tap — standard button press.
    func lightTap() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    /// Medium tap — logging a shift.
    func mediumTap() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    /// Heavy success — completing a purchase or adding a Pack member.
    func heavySuccess() {
        heavyGenerator.impactOccurred()
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Payment success — subscription confirmed.
    func paymentSuccess() {
        heavyGenerator.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.heavyGenerator.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.notificationGenerator.notificationOccurred(.success)
        }
    }

    /// Error feedback.
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
}
