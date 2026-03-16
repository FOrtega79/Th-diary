import Foundation
import SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var isEditing = false
    @Published var editUsername: String = ""
    @Published var editBio: String = ""
    @Published var editSecondaryTheriotype: Theriotype?
    @Published var selectedImage: UIImage?

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Bio ad-unlock expiry
    @Published var bioUnlockExpiry: Date?

    var isBioUnlocked: Bool {
        guard let expiry = bioUnlockExpiry else { return false }
        return expiry > Date()
    }

    private let firestore = FirestoreService.shared
    private let storage   = StorageService.shared

    // MARK: - Begin edit

    func beginEditing(user: TherianUser) {
        editUsername = user.username
        editBio = user.bio
        if let secondary = user.secondaryTheriotype {
            editSecondaryTheriotype = Theriotype(rawValue: secondary)
        }
        isEditing = true
    }

    // MARK: - Save profile

    func saveProfile(user: inout TherianUser) async {
        isLoading = true
        defer { isLoading = false }

        let trimmedUsername = editUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedUsername.count >= 3 else {
            errorMessage = "Username must be at least 3 characters."
            return
        }

        // Check username uniqueness if changed
        if trimmedUsername != user.username {
            do {
                let taken = try await firestore.isUsernameTaken(trimmedUsername)
                guard !taken else {
                    errorMessage = "That username is already taken."
                    return
                }
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        user.username = trimmedUsername
        user.bio = editBio
        user.secondaryTheriotype = editSecondaryTheriotype?.rawValue

        // Upload profile image if changed
        if let image = selectedImage {
            do {
                let url = try await storage.uploadProfileImage(image, userId: user.uid)
                user.profileImageUrl = url
            } catch {
                errorMessage = "Image upload failed: \(error.localizedDescription)"
                return
            }
        }

        do {
            try await firestore.updateUser(user)
            isEditing = false
            successMessage = "Profile updated!"
            HapticsManager.shared.heavySuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Ad unlock for bio

    func unlockBioForDay() {
        bioUnlockExpiry = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
    }
}
