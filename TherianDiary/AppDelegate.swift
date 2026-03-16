import UIKit
import FirebaseCore
import FirebaseCrashlytics
import FirebaseAnalytics
import GoogleSignIn
import RevenueCat
import GoogleMobileAds

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Firebase
        FirebaseApp.configure()

        // Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)

        // Analytics
        Analytics.setAnalyticsCollectionEnabled(true)

        // RevenueCat
        RevenueCatService.shared.configure()

        // AdMob
        AdMobService.shared.configure()

        return true
    }

    // MARK: - Google Sign-In URL handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
