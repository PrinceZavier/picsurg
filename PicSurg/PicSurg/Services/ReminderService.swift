import Foundation
import Combine
import UserNotifications

/// Frequency options for scan reminders
enum ReminderFrequency: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

/// Service for managing scan reminder notifications
@MainActor
final class ReminderService: ObservableObject {

    // MARK: - Singleton

    static let shared = ReminderService()

    // MARK: - Published Properties

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    @Published var frequency: ReminderFrequency {
        didSet {
            UserDefaults.standard.set(frequency.rawValue, forKey: Self.frequencyKey)
            if isEnabled { scheduleReminder() }
        }
    }

    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: Self.timeKey)
            if isEnabled { scheduleReminder() }
        }
    }

    @Published var weekday: Int { // 1 = Sunday, 7 = Saturday
        didSet {
            UserDefaults.standard.set(weekday, forKey: Self.weekdayKey)
            if isEnabled { scheduleReminder() }
        }
    }

    @Published var notificationPermission: UNAuthorizationStatus = .notDetermined

    // MARK: - Keys

    private static let enabledKey = "com.picsurg.reminder.enabled"
    private static let frequencyKey = "com.picsurg.reminder.frequency"
    private static let timeKey = "com.picsurg.reminder.time"
    private static let weekdayKey = "com.picsurg.reminder.weekday"

    private static let notificationIdentifier = "com.picsurg.scanReminder"

    // MARK: - Init

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)

        let freqRaw = UserDefaults.standard.string(forKey: Self.frequencyKey) ?? "daily"
        self.frequency = ReminderFrequency(rawValue: freqRaw) ?? .daily

        if let timeInterval = UserDefaults.standard.object(forKey: Self.timeKey) as? TimeInterval {
            self.reminderTime = Date(timeIntervalSince1970: timeInterval)
        } else {
            // Default: 6:00 PM
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 18
            components.minute = 0
            self.reminderTime = Calendar.current.date(from: components) ?? Date()
        }

        self.weekday = UserDefaults.standard.object(forKey: Self.weekdayKey) as? Int ?? 6 // Friday

        checkPermission()
    }

    // MARK: - Permission

    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.notificationPermission = settings.authorizationStatus
            }
        }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            notificationPermission = granted ? .authorized : .denied
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    func scheduleReminder() {
        cancelReminder()
        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to PicSurg"
        content.body = "Check your camera roll for surgical photos that need securing."
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

        if frequency == .weekly {
            dateComponents.weekday = weekday
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.notificationIdentifier]
        )
    }

    // MARK: - Reset

    func resetAll() {
        isEnabled = false
        cancelReminder()
        UserDefaults.standard.removeObject(forKey: Self.enabledKey)
        UserDefaults.standard.removeObject(forKey: Self.frequencyKey)
        UserDefaults.standard.removeObject(forKey: Self.timeKey)
        UserDefaults.standard.removeObject(forKey: Self.weekdayKey)
    }
}
