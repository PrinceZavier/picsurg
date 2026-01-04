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

    /// Date of oldest photo that has been scanned (for continuing from where we left off)
    @Published var oldestScannedPhotoDate: Date?

    /// Total photos in library (for progress display)
    @Published var totalLibraryPhotos: Int = 0

    /// Total photos scanned across all sessions
    @Published var totalPhotosScanned: Int = 0

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
    private static let oldestScannedDateKey = "com.picsurg.oldestScannedDate"
    private static let totalScannedKey = "com.picsurg.totalScanned"

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

        // Load batch scanning state
        if let oldestScannedInterval = UserDefaults.standard.object(forKey: Self.oldestScannedDateKey) as? TimeInterval {
            oldestScannedPhotoDate = Date(timeIntervalSince1970: oldestScannedInterval)
        }
        totalPhotosScanned = UserDefaults.standard.integer(forKey: Self.totalScannedKey)
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

    /// Update batch scan progress after scanning a batch of photos
    func updateBatchScanProgress(oldestPhotoDate: Date, photosScanned: Int) {
        // Only update if this is an older date than we've seen
        if oldestScannedPhotoDate == nil || oldestPhotoDate < oldestScannedPhotoDate! {
            oldestScannedPhotoDate = oldestPhotoDate
            UserDefaults.standard.set(oldestPhotoDate.timeIntervalSince1970, forKey: Self.oldestScannedDateKey)
        }

        totalPhotosScanned += photosScanned
        UserDefaults.standard.set(totalPhotosScanned, forKey: Self.totalScannedKey)
    }

    /// Reset batch scanning progress (e.g., when starting fresh)
    func resetBatchScanProgress() {
        oldestScannedPhotoDate = nil
        totalPhotosScanned = 0
        UserDefaults.standard.removeObject(forKey: Self.oldestScannedDateKey)
        UserDefaults.standard.removeObject(forKey: Self.totalScannedKey)
    }

    /// Calculate scan coverage percentage
    var scanCoveragePercent: Int {
        guard totalLibraryPhotos > 0 else { return 0 }
        return min(100, Int((Double(totalPhotosScanned) / Double(totalLibraryPhotos)) * 100))
    }

    /// Check if there are more photos to scan
    var hasUnscannedPhotos: Bool {
        totalLibraryPhotos > totalPhotosScanned
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
}
