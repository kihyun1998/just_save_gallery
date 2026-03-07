import Foundation
import Photos
import UIKit

/// Handles saving media files to the iOS Photo Library using the Photos framework.
///
/// Uses `PHPhotoLibrary` for saving and supports creating custom albums.
/// Only requires the "Add Photos" permission (`NSPhotoLibraryAddUsageDescription`).
internal class GallerySaver {

    // MARK: - Public

    /// Saves raw bytes to the photo library.
    ///
    /// - Parameters:
    ///   - bytes: The raw media data.
    ///   - name: The desired file name including extension.
    ///   - albumName: An optional album name to save the media into.
    ///   - isVideo: Whether the media is a video.
    ///   - requestPermission: Whether to request permission automatically.
    ///   - completion: Called with the local identifier on success or an error.
    func saveBytes(
        _ bytes: FlutterStandardTypedData,
        name: String,
        albumName: String?,
        isVideo: Bool,
        requestPermission: Bool,
        completion: @escaping (Result<String, SaveError>) -> Void
    ) {
        let data = bytes.data

        // Write bytes to a temporary file so we can use the same
        // PHAssetCreationRequest flow for both bytes and file paths.
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(name)

        do {
            try data.write(to: tempFile)
        } catch {
            completion(.failure(.unknown(error.localizedDescription)))
            return
        }

        saveFile(
            tempFile.path,
            name: name,
            albumName: albumName,
            isVideo: isVideo,
            requestPermission: requestPermission
        ) { result in
            // Clean up temp file regardless of outcome.
            try? FileManager.default.removeItem(at: tempFile)
            completion(result)
        }
    }

    /// Saves a file at the given path to the photo library.
    ///
    /// - Parameters:
    ///   - filePath: The absolute path to the source file.
    ///   - name: The desired file name including extension.
    ///   - albumName: An optional album name to save the media into.
    ///   - isVideo: Whether the media is a video.
    ///   - requestPermission: Whether to request permission automatically.
    ///   - completion: Called with the local identifier on success or an error.
    func saveFile(
        _ filePath: String,
        name: String,
        albumName: String?,
        isVideo: Bool,
        requestPermission: Bool,
        completion: @escaping (Result<String, SaveError>) -> Void
    ) {
        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            completion(.failure(.fileNotFound("Source file not found: \(filePath)")))
            return
        }

        let performSave = {
            self.addAsset(fileURL: fileURL, isVideo: isVideo, albumName: albumName, completion: completion)
        }

        if requestPermission {
            requestAuthorizationIfNeeded { granted in
                if granted {
                    performSave()
                } else {
                    completion(.failure(.permissionDenied))
                }
            }
        } else {
            performSave()
        }
    }

    // MARK: - Private

    /// Adds an asset to the photo library, optionally placing it in a named album.
    private func addAsset(
        fileURL: URL,
        isVideo: Bool,
        albumName: String?,
        completion: @escaping (Result<String, SaveError>) -> Void
    ) {
        var localIdentifier: String?

        PHPhotoLibrary.shared().performChanges({
            let request: PHAssetChangeRequest
            if isVideo {
                request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)!
            } else {
                request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)!
            }
            let placeholder = request.placeholderForCreatedAsset
            localIdentifier = placeholder?.localIdentifier

            // Add to album if specified.
            if let albumName = albumName, let placeholder = placeholder {
                let album = self.fetchOrCreateAlbum(named: albumName)
                if let album = album {
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                    albumChangeRequest?.addAssets([placeholder] as NSFastEnumeration)
                }
            }
        }) { success, error in
            if success, let id = localIdentifier {
                completion(.success(id))
            } else {
                let message = error?.localizedDescription ?? "Unknown error"
                completion(.failure(.unknown(message)))
            }
        }
    }

    /// Fetches an existing album by name or creates a new one.
    ///
    /// **Note:** This runs synchronously within a `performChanges` block.
    /// The album creation itself is performed via `PHAssetCollectionChangeRequest`.
    private func fetchOrCreateAlbum(named name: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let existing = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: fetchOptions
        )

        if let album = existing.firstObject {
            return album
        }

        // Create album synchronously — this is safe within performChanges.
        PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        return nil
    }

    /// Requests photo library add-only authorization if not already granted.
    private func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        let status: PHAuthorizationStatus
        if #available(iOS 14, *) {
            status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            status = PHPhotoLibrary.authorizationStatus()
        }

        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            } else {
                PHPhotoLibrary.requestAuthorization { newStatus in
                    completion(newStatus == .authorized)
                }
            }
        default:
            completion(false)
        }
    }

    // MARK: - Error

    /// Represents errors that can occur during a gallery save operation.
    enum SaveError: Error {
        case permissionDenied
        case fileNotFound(String)
        case unknown(String)

        var code: String {
            switch self {
            case .permissionDenied: return "PERMISSION_DENIED"
            case .fileNotFound: return "FILE_NOT_FOUND"
            case .unknown: return "UNKNOWN"
            }
        }

        var message: String {
            switch self {
            case .permissionDenied: return "Photo library permission denied by user"
            case .fileNotFound(let msg): return msg
            case .unknown(let msg): return msg
            }
        }
    }
}
