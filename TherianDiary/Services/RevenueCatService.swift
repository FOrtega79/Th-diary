import Foundation
import RevenueCat

// MARK: - RevenueCatService

@MainActor
final class RevenueCatService: ObservableObject {
    static let shared = RevenueCatService()

    @Published var isPremium: Bool = false
    @Published var offerings: Offerings?
    @Published var isLoading: Bool = false

    // Replace with your actual RevenueCat API key
    static let apiKey = "YOUR_REVENUECAT_API_KEY"

    // Entitlement identifier (configure in RevenueCat dashboard)
    static let entitlementID = "therian_pro"

    private init() {}

    // MARK: - Configure (call from AppDelegate)

    func configure() {
        Purchases.configure(withAPIKey: Self.apiKey)
        Purchases.shared.delegate = self as? PurchasesDelegate

        Task {
            await refreshPurchaserInfo()
        }
    }

    func identify(userId: String) {
        Purchases.shared.logIn(userId) { [weak self] _, _, error in
            if let error { print("RevenueCat logIn error: \(error.localizedDescription)") }
            Task { @MainActor in
                await self?.refreshPurchaserInfo()
            }
        }
    }

    func logout() {
        Purchases.shared.logOut { _, _ in }
        isPremium = false
    }

    // MARK: - Offerings

    func fetchOfferings() async {
        isLoading = true
        defer { isLoading = false }
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("RevenueCat offerings error: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await Purchases.shared.purchase(package: package)
        isPremium = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true

        if isPremium {
            HapticsManager.shared.paymentSuccess()
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        let info = try await Purchases.shared.restorePurchases()
        isPremium = info.entitlements[Self.entitlementID]?.isActive == true
    }

    // MARK: - Refresh Status

    func refreshPurchaserInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("RevenueCat refresh error: \(error.localizedDescription)")
        }
    }

    // MARK: - Convenience

    var currentOffering: Offering? {
        offerings?.current
    }

    var monthlyPackage: Package? {
        currentOffering?.monthly
    }

    var annualPackage: Package? {
        currentOffering?.annual
    }
}
