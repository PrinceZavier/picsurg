import Foundation
import Photos
import UIKit
import Combine

/// Service for accessing the iOS Photo Library
@MainActor
final class PhotoService: ObservableObject {

    enum PhotoError: Error {
        case accessDenied
        case fetchFailed
        case imageLoadFailed
        case deleteFailed
        case saveFailed
        case assetUnavailable
    }

    // MARK: - Published Properties

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    /// Published when photo library changes externally (deletions, edits, etc.)
    @Published var libraryChangeCount: Int = 0

    // MARK: - Singleton

    static let shared = PhotoService()

    private let imageManager = PHCachingImageManager()
    private var changeObserver: PhotoLibraryChangeObserver?

    private init() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        setupChangeObserver()
    }

    // MARK: - Change Observer

    private func setupChangeObserver() {
        changeObserver = PhotoLibraryChangeObserver { [weak self] in
            Task { @MainActor in
                self?.libraryChangeCount += 1
            }
        }
        PHPhotoLibrary.shared().register(changeObserver!)
    }

    func unregisterObserver() {
        if let observer = changeObserver {
            PHPhotoLibrary.shared().unregisterChangeObserver(observer)
            changeObserver = nil
        }
    }

    // MARK: - Authorization

    /// Request photo library access
    func requestAuthorization() async -> PHAuthorizationStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
        return status
    }

    var hasFullAccess: Bool {
        authorizationStatus == .authorized
    }

    var hasLimitedAccess: Bool {
        authorizationStatus == .limited
    }

    var canAccessPhotos: Bool {
        hasFullAccess || hasLimitedAccess
    }

    // MARK: - Fetch Photos

    /// Fetch all photos from camera roll
    func fetchAllPhotos() -> [PHAsset] {
        guard canAccessPhotos else { return [] }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        return assets
    }

    /// Fetch photos from a specific date range
    func fetchPhotos(from startDate: Date, to endDate: Date) -> [PHAsset] {
        guard canAccessPhotos else { return [] }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(
            format: "mediaType == %d AND creationDate >= %@ AND creationDate <= %@",
            PHAssetMediaType.image.rawValue,
            startDate as NSDate,
            endDate as NSDate
        )

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        return assets
    }

    // MARK: - Load Images

    /// Load thumbnail image for an asset
    func loadThumbnail(for asset: PHAsset, size: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // Only continue if this is the final image (not a degraded preview)
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// Load full-resolution image data for an asset
    func loadFullResolutionImageData(for asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            imageManager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: PhotoError.imageLoadFailed)
                }
            }
        }
    }

    /// Load full-resolution UIImage for an asset
    func loadFullResolutionImage(for asset: PHAsset) async throws -> UIImage {
        let data = try await loadFullResolutionImageData(for: asset)
        guard let image = UIImage(data: data) else {
            throw PhotoError.imageLoadFailed
        }
        return image
    }

    // MARK: - Delete Photos

    /// Delete photos from the library
    func deletePhotos(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }

    /// Delete a single photo from the library
    func deletePhoto(_ asset: PHAsset) async throws {
        try await deletePhotos([asset])
    }

    // MARK: - Caching

    /// Start caching thumbnails for assets
    func startCaching(assets: [PHAsset], size: CGSize = CGSize(width: 200, height: 200)) {
        imageManager.startCachingImages(
            for: assets,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        )
    }

    /// Stop caching thumbnails
    func stopCaching(assets: [PHAsset], size: CGSize = CGSize(width: 200, height: 200)) {
        imageManager.stopCachingImages(
            for: assets,
            targetSize: size,
            contentMode: .aspectFill,
            options: nil
        )
    }

    /// Stop all caching
    func stopAllCaching() {
        imageManager.stopCachingImagesForAllAssets()
    }

    // MARK: - Save Photos

    /// Save an image to the camera roll
    func saveToPhotoLibrary(_ imageData: Data) async throws {
        guard canAccessPhotos else {
            throw PhotoError.accessDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: imageData, options: nil)
        }
    }

    /// Save a UIImage to the camera roll
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            throw PhotoError.saveFailed
        }
        try await saveToPhotoLibrary(data)
    }

    // MARK: - Asset Validation

    /// Check if an asset still exists and is available
    func assetExists(identifier: String) -> Bool {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return result.count > 0
    }

    /// Filter out identifiers for assets that no longer exist
    func filterExistingAssets(identifiers: [String]) -> [String] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var existingIds: [String] = []
        result.enumerateObjects { asset, _, _ in
            existingIds.append(asset.localIdentifier)
        }
        return existingIds
    }

    /// Get assets by identifiers, returning only those that exist
    func fetchExistingAssets(identifiers: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
}

// MARK: - Photo Library Change Observer

/// Observer for photo library changes (runs on background thread)
final class PhotoLibraryChangeObserver: NSObject, PHPhotoLibraryChangeObserver {
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        super.init()
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Notify on any change - the main app can decide how to handle it
        onChange()
    }
}
