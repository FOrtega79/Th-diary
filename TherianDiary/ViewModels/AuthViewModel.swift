import Foundation
import SwiftUI
import FirebaseAuth
import AuthenticationServices

// MARK: - AuthViewModel

@MainActor
final class AuthViewModel: ObservableObject {

    enum AuthState {
        case splash
        case unauthenticated
        case onboarding          // signed in but no Firestore profile yet
        case authenticated
    }

    @Published var state: AuthState = .splash
    @Published var currentTherianUser: TherianUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService    = AuthService.shared
    private let firestoreService = FirestoreService.shared
    private let revenueCatService = RevenueCatService.shared

    init() {
        observeAuthChanges()
    }

    // MARK: - Observe Firebase Auth

    private func observeAuthChanges() {
        // Listening happens inside AuthService; we poll after splash delay.
        Task {
            try? await Task.sleep(for: .seconds(2))  // splash duration
            await checkAuthState()
        }
    }

    func checkAuthState() async {
        guard let user = authService.currentUser else {
            state = .unauthenticated
            return
        }

        do {
            if let profile = try await firestoreService.fetchUser(uid: user.uid) {
                currentTherianUser = profile
                revenueCatService.identify(userId: user.uid)
                state = .authenticated
            } else {
                state = .onboarding
            }
        } catch {
            state = .unauthenticated
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Apple Sign-In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.handleAppleSignInCompletion(result: result)
            await checkAuthState()
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle(presenting vc: UIViewController) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signInWithGoogle(presenting: vc)
            await checkAuthState()
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }

    // MARK: - Onboarding — Create Profile

    func createProfile(username: String, primaryTheriotype: Theriotype) async {
        guard let uid = authService.currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        // Validate username
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3, trimmed.count <= 20 else {
            errorMessage = "Username must be 3–20 characters."
            return
        }

        do {
            let taken = try await firestoreService.isUsernameTaken(trimmed)
            guard !taken else {
                errorMessage = "That username is taken. Try another!"
                return
            }

            let profile = TherianUser(
                uid: uid,
                username: trimmed,
                primaryTheriotype: primaryTheriotype.rawValue
            )
            try await firestoreService.createUser(profile)
            currentTherianUser = profile
            revenueCatService.identify(userId: uid)
            state = .authenticated
            HapticsManager.shared.heavySuccess()
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try authService.signOut()
            revenueCatService.logout()
            currentTherianUser = nil
            state = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh current user

    func refreshCurrentUser() async {
        guard let uid = authService.currentUser?.uid else { return }
        if let profile = try? await firestoreService.fetchUser(uid: uid) {
            currentTherianUser = profile
        }
    }
}
