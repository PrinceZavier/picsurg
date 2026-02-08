import Foundation
import SwiftUI
import Combine

/// Activity item for tracking user actions
struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let type: ActivityType
    let count: Int
    let date: Date

    enum ActivityType: String, Codable {
        case scanned
        case secured
        case deleted
        case shared
        case restored
    }

    var message: String {
        switch type {
        case .scanned: return "Scanned \(count) photos"
        case .secured: return "Secured \(count) photo\(count == 1 ? "" : "s")"
        case .deleted: return "Deleted \(count) photo\(count == 1 ? "" : "s")"
        case .shared: return "Shared \(count) photo\(count == 1 ? "" : "s")"
        case .restored: return "Restored \(count) photo\(count == 1 ? "" : "s") to camera roll"
        }
    }

    var icon: String {
        switch type {
        case .scanned: return "magnifyingglass"
        case .secured: return "lock.fill"
        case .deleted: return "trash"
        case .shared: return "square.and.arrow.up"
        case .restored: return "arrow.uturn.backward.circle"
        }
    }

    var color: Color {
        switch type {
        case .scanned: return Theme.Colors.primary
        case .secured: return Theme.Colors.secure
        case .deleted: return Theme.Colors.error
        case .shared: return .blue
        case .restored: return Theme.Colors.success
        }
    }
}

/// User-friendly error messages for display
struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isRecoverable: Bool

    static func photoAccessDenied() -> AppError {
        AppError(
            title: "Photo Access Required",
            message: "PicSurg needs access to your photos. Please go to Settings > Privacy > Photos and enable access.",
            isRecoverable: true
        )
    }

    static func encryptionFailed() -> AppError {
        AppError(
            title: "Encryption Failed",
            message: "Some photos could not be encrypted. They remain safely in your camera roll.",
            isRecoverable: false
        )
    }

    static func vaultLoadFailed() -> AppError {
        AppError(
            title: "Vault Error",
            message: "Could not load your secured photos. Please try again.",
            isRecoverable: true
        )
    }

    static func deleteFailed() -> AppError {
        AppError(
            title: "Delete Failed",
            message: "Could not delete the photo. Please try again.",
            isRecoverable: true
        )
    }

    static func storageFull() -> AppError {
        AppError(
            title: "Storage Full",
            message: "Not enough storage space to secure photos. Please free up some space and try again.",
            isRecoverable: false
        )
    }

    static func settingsOperationFailed(_ operation: String) -> AppError {
        AppError(
            title: "\(operation) Failed",
            message: "Could not complete the operation. Please try again.",
            isRecoverable: true
        )
    }

    static func mlModelFailed() -> AppError {
        AppError(
            title: "Scan Not Available",
            message: "The photo scanner could not be loaded. Please restart the app.",
            isRecoverable: false
        )
    }
}

/// Central app state management
@MainActor
final class AppState: ObservableObject {

    // MARK: - Authentication State

    @Published var isAuthenticated = false
    @Published var isOnboardingComplete = false

    // MARK: - Scan State

    @Published var isScanning = false
    @Published var scanProgress: Float = 0
    @Published var scanResults: [MLService.ScanResult] = []
    @Published var lastScanDate: Date?

    // MARK: - Batch Scanning State

    /// Set of photo identifiers that have been scanned
    private var scannedPhotoIds: Set<String> = []

    /// Total photos in library (for progress display)
    @Published var totalLibraryPhotos: Int = 0

    /// Total photos scanned across all sessions
    @Published var totalPhotosScanned: Int = 0

    /// Whether the initial full library scan has been completed
    @Published var hasCompletedInitialScan: Bool = false

    // MARK: - Activity Feed

    @Published var recentActivity: [ActivityItem] = []

    // MARK: - Error State

    @Published var currentError: AppError?

    // MARK: - Navigation

    @Published var selectedTab: Tab = .home

    enum Tab {
        case home
        case vault
        case settings
    }

    // MARK: - Error Handling

    func showError(_ error: AppError) {
        currentError = error
    }

    func clearError() {
        currentError = nil
    }

    // MARK: - Persistence Keys

    private static let onboardingCompleteKey = "com.picsurg.onboardingComplete"
    private static let lastScanDateKey = "com.picsurg.lastScanDate"
    private static let recentActivityKey = "com.picsurg.recentActivity"
    private static let scannedPhotoIdsKey = "com.picsurg.scannedPhotoIds"
    private static let totalScannedKey = "com.picsurg.totalScanned"
    private static let initialScanCompleteKey = "com.picsurg.initialScanComplete"

    // MARK: - Singleton

    static let shared = AppState()

    private init() {
        loadPersistedState()
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        isOnboardingComplete = UserDefaults.standard.bool(forKey: Self.onboardingCompleteKey)

        if let lastScanInterval = UserDefaults.standard.object(forKey: Self.lastScanDateKey) as? TimeInterval {
            lastScanDate = Date(timeIntervalSince1970: lastScanInterval)
        }

        if let activityData = UserDefaults.standard.data(forKey: Self.recentActivityKey),
           let activities = try? JSONDecoder().decode([ActivityItem].self, from: activityData) {
            recentActivity = activities
        }

        // Load scanned photo IDs
        if let idsArray = UserDefaults.standard.array(forKey: Self.scannedPhotoIdsKey) as? [String] {
            scannedPhotoIds = Set(idsArray)
        }
        totalPhotosScanned = UserDefaults.standard.integer(forKey: Self.totalScannedKey)
        hasCompletedInitialScan = UserDefaults.standard.bool(forKey: Self.initialScanCompleteKey)
    }

    func setOnboardingComplete() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: Self.onboardingCompleteKey)
    }

    func setLastScanDate(_ date: Date) {
        lastScanDate = date
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.lastScanDateKey)
    }

    // MARK: - Batch Scanning

    /// Check if a photo has already been scanned
    func hasScannedPhoto(id: String) -> Bool {
        scannedPhotoIds.contains(id)
    }

    /// Mark photos as scanned
    func markPhotosAsScanned(ids: [String]) {
        scannedPhotoIds.formUnion(ids)
        totalPhotosScanned = scannedPhotoIds.count
        saveScannedPhotoIds()
    }

    /// Mark initial scan as complete
    func markInitialScanComplete() {
        hasCompletedInitialScan = true
        UserDefaults.standard.set(true, forKey: Self.initialScanCompleteKey)
    }

    private func saveScannedPhotoIds() {
        UserDefaults.standard.set(Array(scannedPhotoIds), forKey: Self.scannedPhotoIdsKey)
        UserDefaults.standard.set(totalPhotosScanned, forKey: Self.totalScannedKey)
    }

    /// Reset batch scanning progress (e.g., when starting fresh)
    func resetBatchScanProgress() {
        scannedPhotoIds.removeAll()
        totalPhotosScanned = 0
        hasCompletedInitialScan = false
        UserDefaults.standard.removeObject(forKey: Self.scannedPhotoIdsKey)
        UserDefaults.standard.removeObject(forKey: Self.totalScannedKey)
        UserDefaults.standard.removeObject(forKey: Self.initialScanCompleteKey)
    }

    /// Get IDs of photos that haven't been scanned yet
    func getUnscannedPhotoIds(from allIds: [String]) -> [String] {
        allIds.filter { !scannedPhotoIds.contains($0) }
    }

    // MARK: - Activity Logging

    func logActivity(_ type: ActivityItem.ActivityType, count: Int) {
        let item = ActivityItem(id: UUID(), type: type, count: count, date: Date())
        recentActivity.insert(item, at: 0)

        // Keep only last 10 activities
        if recentActivity.count > 10 {
            recentActivity = Array(recentActivity.prefix(10))
        }

        saveActivity()
    }

    private func saveActivity() {
        if let data = try? JSONEncoder().encode(recentActivity) {
            UserDefaults.standard.set(data, forKey: Self.recentActivityKey)
        }
    }

    // MARK: - Reset

    func resetAllData() {
        isAuthenticated = false
        isOnboardingComplete = false
        scanResults = []
        lastScanDate = nil
        recentActivity = []

        // Reset batch scanning state
        resetBatchScanProgress()

        UserDefaults.standard.removeObject(forKey: Self.onboardingCompleteKey)
        UserDefaults.standard.removeObject(forKey: Self.lastScanDateKey)
        UserDefaults.standard.removeObject(forKey: Self.recentActivityKey)
    }

    /// Get the last scan activity for display
    var lastScanActivity: ActivityItem? {
        recentActivity.first { $0.type == .scanned }
    }
}
