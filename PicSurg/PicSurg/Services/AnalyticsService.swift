import Foundation
import TelemetryDeck

/// Type-safe analytics event names
enum AnalyticsEvent: String {
    // Core beta metrics
    case appOpened = "app_opened"
    case scanInitiated = "scan_initiated"
    case scanCompleted = "scan_completed"
    case reviewOpened = "review_opened"
    case reviewCompleted = "review_completed"
    case reviewCancelled = "review_cancelled"
    case photosVaulted = "photos_vaulted"
    case vaultViewed = "vault_viewed"

    // Behavioral insights
    case photoDeleted = "photo_deleted"
    case photoRestored = "photo_restored"
    case photoShared = "photo_shared"
    case onboardingCompleted = "onboarding_completed"
    case settingsChanged = "settings_changed"
    case authAttempt = "auth_attempt"
    case manualAddOpened = "manual_add_opened"
}

/// Lightweight analytics service wrapping TelemetryDeck
final class AnalyticsService {

    static let shared = AnalyticsService()

    private static let appID = "CBB8AE8C-C837-448F-8B57-590628AAAF6E"

    private static let lastOpenKey = "com.picsurg.analytics.lastAppOpen"

    private var isInitialized = false

    private init() {}

    /// Initialize TelemetryDeck SDK. Call once from PicSurgApp.init().
    func initialize() {
        guard !isInitialized else { return }

        let config = TelemetryDeck.Config(appID: Self.appID)
        TelemetryDeck.initialize(config: config)
        isInitialized = true
    }

    /// Track an analytics event with optional parameters.
    /// Never blocks the UI — fires on a background thread.
    func track(_ event: AnalyticsEvent, parameters: [String: String] = [:]) {
        guard isInitialized else { return }

        #if DEBUG
        print("[Analytics] \(event.rawValue): \(parameters)")
        #endif

        TelemetryDeck.signal(event.rawValue, parameters: parameters)
    }

    /// Track app opened with days-since-last-open metadata.
    func trackAppOpened() {
        let lastOpen = UserDefaults.standard.object(forKey: Self.lastOpenKey) as? Date
        var params: [String: String] = [:]
        if let lastOpen = lastOpen {
            let days = Calendar.current.dateComponents([.day], from: lastOpen, to: Date()).day ?? 0
            params["daysSinceLastOpen"] = String(days)
        }
        UserDefaults.standard.set(Date(), forKey: Self.lastOpenKey)
        track(.appOpened, parameters: params)
    }
}
