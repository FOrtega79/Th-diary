import Foundation
import FirebaseStorage
import UIKit

// MARK: - StorageService

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Profile Image Upload

    /// Uploads a profile image and returns the download URL string.
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            throw StorageError.compressionFailed
        }

        let ref = storage.reference()
            .child("profileImages")
            .child("\(userId).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - Delete Profile Image

    func deleteProfileImage(userId: String) async throws {
        let ref = storage.reference()
            .child("profileImages")
            .child("\(userId).jpg")
        try await ref.delete()
    }
}

// MARK: - StorageError

enum StorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress image for upload."
        }
    }
}
