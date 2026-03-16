import Foundation
import GoogleMobileAds
import UIKit

// MARK: - AdMobService

@MainActor
final class AdMobService: NSObject, ObservableObject {
    static let shared = AdMobService()

    @Published var isAdLoaded: Bool = false
    @Published var isShowingAd: Bool = false

    // Replace with your real AdMob ad unit IDs
    static let rewardedAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"

    private var rewardedAd: GADRewardedAd?
    private var rewardCallback: ((Bool) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Configure (call from AppDelegate)

    func configure() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        Task { await loadAd() }
    }

    // MARK: - Load

    func loadAd() async {
        do {
            let request = GADRequest()
            rewardedAd = try await GADRewardedAd.load(
                withAdUnitID: Self.rewardedAdUnitID,
                request: request
            )
            rewardedAd?.fullScreenContentDelegate = self
            isAdLoaded = true
        } catch {
            print("AdMob load error: \(error.localizedDescription)")
            isAdLoaded = false
        }
    }

    // MARK: - Show

    /// Present the rewarded ad. Calls `completion(true)` if the user earns the reward.
    func showRewardedAd(
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        guard let ad = rewardedAd else {
            completion(false)
            return
        }

        isShowingAd = true
        rewardCallback = completion

        ad.present(fromRootViewController: viewController) { [weak self] in
            completion(true)
            self?.rewardCallback = nil
            Task { await self?.loadAd() }     // preload next ad
        }
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdMobService: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in
            isShowingAd = false
            if rewardCallback != nil {
                rewardCallback?(false)
                rewardCallback = nil
            }
            await loadAd()
        }
    }

    nonisolated func ad(_ ad: GADFullScreenPresentingAd,
                        didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            isShowingAd = false
            rewardCallback?(false)
            rewardCallback = nil
            await loadAd()
        }
    }
}

// MARK: - AdTrigger enum

enum AdTrigger {
    case packSlot       // Extra pack slot (24h)
    case bioEdit        // Edit bio today
    case statsReveal    // Reveal trigger chart (24h)

    var title: String {
        switch self {
        case .packSlot:    return "Unlock a Pack Slot"
        case .bioEdit:     return "Edit Your Bio Today"
        case .statsReveal: return "Reveal Your Stats"
        }
    }

    var message: String {
        switch self {
        case .packSlot:
            return "Upgrade to Pro to add up to 20 pack members, or watch a short ad to unlock 1 temporary slot for 24 hours!"
        case .bioEdit:
            return "Custom Bios are a Pro feature. Watch a quick ad to edit your bio today!"
        case .statsReveal:
            return "Watch an ad to reveal your Shift Triggers chart for 24 hours."
        }
    }

    var ctaLabel: String { "Watch Ad" }
}
