import SwiftUI
import FirebaseCore

// AppDelegate is the entry point via @main in AppDelegate.swift
// This file wires up the SwiftUI app scene.

struct TherianDiaryApp: App {
    @StateObject private var authVM         = AuthViewModel()
    @StateObject private var revenueCatService = RevenueCatService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(revenueCatService)
        }
    }
}

// MARK: - RootView

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            switch authVM.state {
            case .splash:
                SplashView()

            case .unauthenticated:
                AuthView()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))

            case .onboarding:
                OnboardingView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))

            case .authenticated:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authVM.state)
    }
}
