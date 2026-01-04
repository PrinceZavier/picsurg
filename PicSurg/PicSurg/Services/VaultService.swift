import Foundation
import UIKit

// MARK: - Vault Schema Version

/// Current vault schema version - increment when making breaking changes
/// - Version 1: Initial schema (id, originalDate, addedDate, imagePath, thumbnailPath)
/// - Version 2: Added originalAssetId for de-duplication
let kCurrentVaultSchemaVersion = 2

/// Service for managing the encrypted photo vault
///
/// ## Vault Directory Structure
/// ```
/// Documents/
/// └── Vault/                           (excluded from iCloud backup)
///     ├── index.encrypted              (AES-256-GCM encrypted JSON array of VaultPhoto)
///     └── photos/
///         ├── {uuid}.encrypted         (AES-256-GCM encrypted full-resolution JPEG)
///         └── {uuid}_thumb.encrypted   (AES-256-GCM encrypted thumbnail JPEG, ~300px)
/// ```
///
/// ## Encryption Details
/// - All files use AES-256-GCM via CryptoService
/// - Encryption key derived from user's PIN using PBKDF2-HMAC-SHA256
/// - Each file has unique IV (nonce) prepended to ciphertext
///
/// ## Index Schema (VaultPhoto JSON)
/// ```json
/// {
///   "id": "uuid-string",           // Unique photo identifier
///   "originalDate": "ISO8601",     // Original capture date from EXIF
///   "addedDate": "ISO8601",        // Date added to vault
///   "imagePath": "uuid.encrypted", // Filename of encrypted full image
///   "thumbnailPath": "uuid_thumb.encrypted" // Filename of encrypted thumbnail
/// }
/// ```
///
/// ## Memory Caching
/// - Decrypted thumbnails cached in NSCache (max 100 items, ~5MB)
/// - Cache automatically evicts on memory pressure
/// - Cache cleared on vault clear or photo deletion
final class VaultService {

    enum VaultError: Error {
        case directoryCreationFailed
        case saveFailed
        case loadFailed
        case photoNotFound
        case indexCorrupted
    }

    // MARK: - Singleton

    static let shared = VaultService()

    // MARK: - Thumbnail Cache

    /// In-memory cache for decrypted thumbnails to avoid repeated decryption
    private var thumbnailCache = NSCache<NSString, UIImage>()

    /// Maximum number of thumbnails to cache (adjust based on memory constraints)
    private let maxCachedThumbnails = 100

    private init() {
        setupVaultDirectory()
        configureThumbnailCache()
    }

    private func configureThumbnailCache() {
        thumbnailCache.countLimit = maxCachedThumbnails
        // Approximate ~50KB per thumbnail = ~5MB total cache
        thumbnailCache.totalCostLimit = 5 * 1024 * 1024
    }

    // MARK: - Directory Paths

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var vaultDirectory: URL {
        documentsDirectory.appendingPathComponent("Vault", isDirectory: true)
    }

    private var photosDirectory: URL {
        vaultDirectory.appendingPathComponent("photos", isDirectory: true)
    }

    private var indexFile: URL {
        vaultDirectory.appendingPathComponent("index.encrypted")
    }

    private var metadataFile: URL {
        vaultDirectory.appendingPathComponent("metadata.json")
    }

    // MARK: - Setup

    private func setupVaultDirectory() {
        let fileManager = FileManager.default

        // Create vault directory if needed
        if !fileManager.fileExists(atPath: vaultDirectory.path) {
            try? fileManager.createDirectory(at: vaultDirectory, withIntermediateDirectories: true)
        }

        // Create photos subdirectory
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }

        // Exclude from backup
        excludeFromBackup(vaultDirectory)

        // Initialize or migrate vault metadata
        initializeOrMigrateVault()
    }

    // MARK: - Vault Versioning & Migration

    private var vaultMetadata: VaultMetadata?

    private func initializeOrMigrateVault() {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: metadataFile.path) {
            // Load existing metadata
            if let data = try? Data(contentsOf: metadataFile),
               let metadata = try? JSONDecoder().decode(VaultMetadata.self, from: data) {
                vaultMetadata = metadata

                // Check if migration is needed
                if metadata.schemaVersion < kCurrentVaultSchemaVersion {
                    migrateVault(from: metadata.schemaVersion)
                }
            }
        } else if fileManager.fileExists(atPath: indexFile.path) {
            // Existing vault without metadata (v1) - create metadata and migrate
            vaultMetadata = VaultMetadata(
                schemaVersion: 1,
                createdAt: Date(),
                lastAccessedAt: Date(),
                appVersion: appVersion
            )
            saveMetadata()
            migrateVault(from: 1)
        } else {
            // New vault - create with current schema version
            vaultMetadata = VaultMetadata(
                schemaVersion: kCurrentVaultSchemaVersion,
                createdAt: Date(),
                lastAccessedAt: Date(),
                appVersion: appVersion
            )
            saveMetadata()
        }
    }

    private func migrateVault(from oldVersion: Int) {
        var currentVersion = oldVersion

        // Apply migrations sequentially
        while currentVersion < kCurrentVaultSchemaVersion {
            switch currentVersion {
            case 1:
                // v1 -> v2: Add originalAssetId field (handled by Codable optional)
                // No data migration needed - new field is optional
                print("📦 Vault migration v1 → v2: Added originalAssetId field")
                currentVersion = 2

            default:
                break
            }
        }

        // Update metadata with new version
        vaultMetadata?.schemaVersion = kCurrentVaultSchemaVersion
        vaultMetadata?.lastAccessedAt = Date()
        vaultMetadata?.appVersion = appVersion
        saveMetadata()

        print("✅ Vault migrated to schema version \(kCurrentVaultSchemaVersion)")
    }

    private func saveMetadata() {
        guard let metadata = vaultMetadata else { return }
        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: metadataFile)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Get current vault schema version
    var schemaVersion: Int {
        vaultMetadata?.schemaVersion ?? kCurrentVaultSchemaVersion
    }

    private func excludeFromBackup(_ url: URL) {
        var resourceURL = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? resourceURL.setResourceValues(resourceValues)
    }

    // MARK: - Vault Index

    private var vaultIndex: [VaultPhoto] = []
    private var indexLoaded = false

    /// Load the vault index from encrypted storage
    func loadIndex() throws -> [VaultPhoto] {
        if indexLoaded {
            return vaultIndex
        }

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: indexFile.path) else {
            vaultIndex = []
            indexLoaded = true
            return vaultIndex
        }

        let encryptedData = try Data(contentsOf: indexFile)
        let decryptedData = try CryptoService.decrypt(encryptedData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        vaultIndex = try decoder.decode([VaultPhoto].self, from: decryptedData)
        indexLoaded = true

        return vaultIndex
    }

    /// Save the vault index
    private func saveIndex() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let indexData = try encoder.encode(vaultIndex)
        let encryptedData = try CryptoService.encrypt(indexData)
        try encryptedData.write(to: indexFile)
    }

    // MARK: - Photo Management

    /// Add a photo to the vault
    /// - Parameters:
    ///   - imageData: The full-resolution image data
    ///   - originalDate: The original capture date
    ///   - thumbnailData: Optional thumbnail data (will be generated if not provided)
    ///   - originalAssetId: Optional iOS photo library asset identifier for de-duplication
    /// - Returns: The created VaultPhoto
    @discardableResult
    func addPhoto(imageData: Data, originalDate: Date, thumbnailData: Data? = nil, originalAssetId: String? = nil) throws -> VaultPhoto {
        // Load index if needed
        _ = try loadIndex()

        // Generate unique ID
        let id = UUID()

        // Generate thumbnail if not provided
        let thumbnail: Data
        if let providedThumbnail = thumbnailData {
            thumbnail = providedThumbnail
        } else {
            thumbnail = generateThumbnail(from: imageData) ?? imageData
        }

        // Encrypt and save full image
        let encryptedImage = try CryptoService.encrypt(imageData)
        let imagePath = photosDirectory.appendingPathComponent("\(id.uuidString).encrypted")
        try encryptedImage.write(to: imagePath)

        // Encrypt and save thumbnail
        let encryptedThumbnail = try CryptoService.encrypt(thumbnail)
        let thumbnailPath = photosDirectory.appendingPathComponent("\(id.uuidString)_thumb.encrypted")
        try encryptedThumbnail.write(to: thumbnailPath)

        // Create vault photo entry
        let vaultPhoto = VaultPhoto(
            id: id,
            originalDate: originalDate,
            addedDate: Date(),
            imagePath: imagePath.lastPathComponent,
            thumbnailPath: thumbnailPath.lastPathComponent,
            originalAssetId: originalAssetId
        )

        // Add to index and save
        vaultIndex.append(vaultPhoto)
        try saveIndex()

        return vaultPhoto
    }

    /// Get decrypted full-resolution image data
    func getPhoto(id: UUID) throws -> Data {
        _ = try loadIndex()

        guard let photo = vaultIndex.first(where: { $0.id == id }) else {
            throw VaultError.photoNotFound
        }

        let imagePath = photosDirectory.appendingPathComponent(photo.imagePath)
        let encryptedData = try Data(contentsOf: imagePath)
        return try CryptoService.decrypt(encryptedData)
    }

    /// Get decrypted thumbnail data
    func getThumbnail(id: UUID) throws -> Data {
        _ = try loadIndex()

        guard let photo = vaultIndex.first(where: { $0.id == id }) else {
            throw VaultError.photoNotFound
        }

        let thumbnailPath = photosDirectory.appendingPathComponent(photo.thumbnailPath)
        let encryptedData = try Data(contentsOf: thumbnailPath)
        return try CryptoService.decrypt(encryptedData)
    }

    /// Get cached thumbnail image, decrypting only if not in cache
    func getCachedThumbnail(id: UUID) throws -> UIImage {
        let cacheKey = id.uuidString as NSString

        // Check cache first
        if let cachedImage = thumbnailCache.object(forKey: cacheKey) {
            return cachedImage
        }

        // Decrypt and cache
        let data = try getThumbnail(id: id)
        guard let image = UIImage(data: data) else {
            throw VaultError.loadFailed
        }

        // Cache with approximate cost (data size)
        thumbnailCache.setObject(image, forKey: cacheKey, cost: data.count)

        return image
    }

    /// Preload thumbnails into cache for better scrolling performance
    func preloadThumbnails(for photoIds: [UUID]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            for id in photoIds {
                let cacheKey = id.uuidString as NSString

                // Skip if already cached
                guard self.thumbnailCache.object(forKey: cacheKey) == nil else { continue }

                do {
                    let data = try self.getThumbnail(id: id)
                    if let image = UIImage(data: data) {
                        self.thumbnailCache.setObject(image, forKey: cacheKey, cost: data.count)
                    }
                } catch {
                    // Silently skip failed preloads
                }
            }
        }
    }

    /// Clear the thumbnail cache (useful on memory warnings)
    func clearThumbnailCache() {
        thumbnailCache.removeAllObjects()
    }

    /// Remove a specific thumbnail from cache
    func removeThumbnailFromCache(id: UUID) {
        thumbnailCache.removeObject(forKey: id.uuidString as NSString)
    }

    /// Get all vault photos (metadata only)
    func listPhotos() throws -> [VaultPhoto] {
        try loadIndex()
    }

    /// Get set of original asset IDs for photos already in vault
    /// Used to skip already-secured photos during re-scans
    func getSecuredAssetIds() -> Set<String> {
        let photos = (try? loadIndex()) ?? []
        return Set(photos.compactMap { $0.originalAssetId })
    }

    /// Delete a photo from the vault
    func deletePhoto(id: UUID) throws {
        _ = try loadIndex()

        guard let index = vaultIndex.firstIndex(where: { $0.id == id }) else {
            throw VaultError.photoNotFound
        }

        let photo = vaultIndex[index]
        let fileManager = FileManager.default

        // Delete encrypted files
        let imagePath = photosDirectory.appendingPathComponent(photo.imagePath)
        let thumbnailPath = photosDirectory.appendingPathComponent(photo.thumbnailPath)

        try? fileManager.removeItem(at: imagePath)
        try? fileManager.removeItem(at: thumbnailPath)

        // Remove from cache
        removeThumbnailFromCache(id: id)

        // Remove from index
        vaultIndex.remove(at: index)
        try saveIndex()
    }

    /// Get vault statistics
    var statistics: VaultStatistics {
        let photos = (try? loadIndex()) ?? []
        let fileManager = FileManager.default

        var totalSize: Int64 = 0
        for photo in photos {
            let imagePath = photosDirectory.appendingPathComponent(photo.imagePath)
            let thumbnailPath = photosDirectory.appendingPathComponent(photo.thumbnailPath)

            if let imageAttrs = try? fileManager.attributesOfItem(atPath: imagePath.path),
               let imageSize = imageAttrs[.size] as? Int64 {
                totalSize += imageSize
            }

            if let thumbAttrs = try? fileManager.attributesOfItem(atPath: thumbnailPath.path),
               let thumbSize = thumbAttrs[.size] as? Int64 {
                totalSize += thumbSize
            }
        }

        return VaultStatistics(photoCount: photos.count, totalSizeBytes: totalSize)
    }

    /// Delete all vault data
    func clearVault() throws {
        let fileManager = FileManager.default

        // Remove entire vault directory
        if fileManager.fileExists(atPath: vaultDirectory.path) {
            try fileManager.removeItem(at: vaultDirectory)
        }

        // Clear thumbnail cache
        clearThumbnailCache()

        // Reset state
        vaultIndex = []
        indexLoaded = false

        // Recreate empty structure
        setupVaultDirectory()
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(from imageData: Data, maxSize: CGFloat = 300) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }

        let scale = min(maxSize / image.size.width, maxSize / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail?.jpegData(compressionQuality: 0.7)
    }
}

// MARK: - Supporting Types

/// Metadata for a single encrypted photo in the vault
///
/// This struct is serialized to JSON and stored encrypted in `index.encrypted`.
/// The actual photo data is stored separately in the `photos/` directory.
struct VaultPhoto: Codable, Identifiable {
    /// Unique identifier used for file naming and lookup
    let id: UUID

    /// Original capture date from photo EXIF metadata
    let originalDate: Date

    /// Date when photo was encrypted and added to vault
    let addedDate: Date

    /// Filename of encrypted full-resolution image (e.g., "uuid.encrypted")
    let imagePath: String

    /// Filename of encrypted thumbnail (e.g., "uuid_thumb.encrypted")
    let thumbnailPath: String

    /// Original PHAsset local identifier from iOS photo library
    /// Used to skip already-secured photos during re-scans
    let originalAssetId: String?
}

/// Statistics about vault storage usage
struct VaultStatistics {
    /// Number of photos stored in vault
    let photoCount: Int

    /// Total encrypted storage size in bytes
    let totalSizeBytes: Int64

    /// Human-readable storage size (e.g., "45.2 MB")
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSizeBytes)
    }
}

/// Vault metadata for versioning and migration tracking
/// Stored unencrypted in metadata.json (contains no sensitive data)
struct VaultMetadata: Codable {
    /// Schema version for data migration
    var schemaVersion: Int

    /// When the vault was first created
    let createdAt: Date

    /// Last time the vault was accessed
    var lastAccessedAt: Date

    /// App version that last accessed this vault
    var appVersion: String
}
