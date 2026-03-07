import Foundation
import Photos

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
        _ bytes: Data,
        name: String,
        albumName: String?,
        isVideo: Bool,
        requestPermission: Bool,
        completion: @escaping (Result<String, SaveError>) -> Void
    ) {
        let data = bytes

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
            let needsReadAccess = albumName != nil
            requestAuthorizationIfNeeded(readWrite: needsReadAccess) { granted in
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
                guard let r = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL) else {
                    return
                }
                request = r
            } else {
                guard let r = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL) else {
                    return
                }
                request = r
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
                let message = error?.localizedDescription ?? "Failed to create asset"
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

    /// Requests photo library authorization if not already granted.
    ///
    /// - Parameter readWrite: When `true`, requests full read/write access
    ///   (needed for album operations). Otherwise requests add-only access.
    private func requestAuthorizationIfNeeded(readWrite: Bool, completion: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            let accessLevel: PHAccessLevel = readWrite ? .readWrite : .addOnly
            let status = PHPhotoLibrary.authorizationStatus(for: accessLevel)

            switch status {
            case .authorized, .limited:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: accessLevel) { newStatus in
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            default:
                completion(false)
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()

            switch status {
            case .authorized:
                completion(true)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    completion(newStatus == .authorized)
                }
            default:
                completion(false)
            }
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
