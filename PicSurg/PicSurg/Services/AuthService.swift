import Foundation
import LocalAuthentication
import CryptoKit
import CommonCrypto
import Combine

/// Service for handling authentication (Face ID, Touch ID, PIN)
@MainActor
final class AuthService: ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthenticated = false
    @Published var isLocked = true
    @Published var failedAttempts = 0
    @Published var lockoutEndTime: Date?

    // MARK: - Biometric Type

    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    // MARK: - Keys

    private static let pinHashKey = "com.picsurg.auth.pinHash"
    private static let pinSaltKey = "com.picsurg.auth.pinSalt"
    private static let biometricEnabledKey = "com.picsurg.auth.biometricEnabled"
    private static let failedAttemptsKey = "com.picsurg.auth.failedAttempts"
    private static let lockoutEndKey = "com.picsurg.auth.lockoutEnd"
    private static let recoveryEmailKey = "com.picsurg.auth.recoveryEmail"
    private static let recoveryCodeKey = "com.picsurg.auth.recoveryCode"
    private static let recoveryCodeExpiryKey = "com.picsurg.auth.recoveryCodeExpiry"

    // MARK: - Singleton

    static let shared = AuthService()

    private init() {
        loadFailedAttempts()
        checkLockoutStatus()
    }

    // MARK: - Biometric Detection

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .none
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "Biometric"
        }
    }

    var isBiometricAvailable: Bool {
        biometricType != .none
    }

    var isBiometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.biometricEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.biometricEnabledKey) }
    }

    // MARK: - PBKDF2 Configuration

    /// Number of PBKDF2 iterations - high enough to be slow for attackers
    /// but fast enough for good UX (~100ms on modern devices)
    private static let pbkdf2Iterations: UInt32 = 100_000
    private static let pbkdf2KeyLength = 32  // 256 bits

    // MARK: - PIN Management

    var hasPINSet: Bool {
        KeychainService.exists(forKey: Self.pinHashKey)
    }

    /// Set up a new PIN using PBKDF2 for secure key derivation
    func setPIN(_ pin: String) throws {
        // Generate a random 32-byte salt
        var saltBytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)
        let salt = Data(saltBytes)

        // Derive key using PBKDF2 (much more secure than SHA-256 for PINs)
        let derivedKey = try deriveKey(from: pin, salt: salt)

        // Store both salt and derived key
        try KeychainService.save(data: salt, forKey: Self.pinSaltKey)
        try KeychainService.save(data: derivedKey, forKey: Self.pinHashKey)

        // Reset failed attempts on new PIN
        failedAttempts = 0
        saveFailedAttempts()
    }

    /// Verify a PIN using PBKDF2
    func verifyPIN(_ pin: String) -> Bool {
        // Check if locked out
        if isLockedOut {
            return false
        }

        guard let salt = try? KeychainService.retrieve(forKey: Self.pinSaltKey),
              let storedKey = try? KeychainService.retrieve(forKey: Self.pinHashKey) else {
            return false
        }

        // Derive key from provided PIN with stored salt
        guard let derivedKey = try? deriveKey(from: pin, salt: salt) else {
            return false
        }

        // Constant-time comparison to prevent timing attacks
        let isValid = constantTimeCompare(derivedKey, storedKey)

        if isValid {
            // Reset failed attempts on success
            failedAttempts = 0
            saveFailedAttempts()
            unlock()
        } else {
            // Increment failed attempts
            failedAttempts += 1
            saveFailedAttempts()
            checkAndApplyLockout()
        }

        return isValid
    }

    /// Derive a key from PIN using PBKDF2-HMAC-SHA256
    private func deriveKey(from pin: String, salt: Data) throws -> Data {
        let pinData = pin.data(using: .utf8)!
        var derivedKey = [UInt8](repeating: 0, count: Self.pbkdf2KeyLength)

        let status = pinData.withUnsafeBytes { pinBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pinBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                    pinData.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    Self.pbkdf2Iterations,
                    &derivedKey,
                    Self.pbkdf2KeyLength
                )
            }
        }

        guard status == kCCSuccess else {
            throw AuthError.keyDerivationFailed
        }

        return Data(derivedKey)
    }

    /// Constant-time comparison to prevent timing attacks
    private func constantTimeCompare(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }

        var result: UInt8 = 0
        for (byte1, byte2) in zip(a, b) {
            result |= byte1 ^ byte2
        }
        return result == 0
    }

    enum AuthError: Error {
        case keyDerivationFailed
        case recoveryEmailNotSet
        case recoveryCodeExpired
        case recoveryCodeInvalid
        case emailSendFailed
    }

    /// Change PIN (requires old PIN verification)
    func changePIN(from oldPIN: String, to newPIN: String) throws -> Bool {
        guard verifyPIN(oldPIN) else {
            return false
        }
        try setPIN(newPIN)
        return true
    }

    /// Delete PIN (resets auth)
    func deletePIN() throws {
        try KeychainService.delete(forKey: Self.pinHashKey)
        try KeychainService.delete(forKey: Self.pinSaltKey)
    }

    // MARK: - Recovery Email

    var recoveryEmail: String? {
        get { UserDefaults.standard.string(forKey: Self.recoveryEmailKey) }
        set {
            if let email = newValue {
                UserDefaults.standard.set(email, forKey: Self.recoveryEmailKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.recoveryEmailKey)
            }
        }
    }

    var hasRecoveryEmail: Bool {
        recoveryEmail != nil && !(recoveryEmail?.isEmpty ?? true)
    }

    /// Mask email for display (e.g., "j***@gmail.com")
    var maskedRecoveryEmail: String? {
        guard let email = recoveryEmail, let atIndex = email.firstIndex(of: "@") else {
            return nil
        }
        let localPart = String(email[..<atIndex])
        let domain = String(email[atIndex...])

        if localPart.count <= 2 {
            return localPart + "***" + domain
        } else {
            let firstChar = localPart.prefix(1)
            let lastChar = localPart.suffix(1)
            return firstChar + "***" + lastChar + domain
        }
    }

    /// Generate and store a 6-digit recovery code (valid for 15 minutes)
    func generateRecoveryCode() -> String {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        UserDefaults.standard.set(code, forKey: Self.recoveryCodeKey)
        let expiry = Date().addingTimeInterval(15 * 60) // 15 minutes
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: Self.recoveryCodeExpiryKey)
        return code
    }

    /// Verify recovery code and reset PIN if valid
    func verifyRecoveryCode(_ code: String) -> Bool {
        guard let storedCode = UserDefaults.standard.string(forKey: Self.recoveryCodeKey),
              let expiryInterval = UserDefaults.standard.object(forKey: Self.recoveryCodeExpiryKey) as? TimeInterval else {
            return false
        }

        let expiry = Date(timeIntervalSince1970: expiryInterval)

        // Check if expired
        guard Date() < expiry else {
            clearRecoveryCode()
            return false
        }

        // Check if code matches
        guard code == storedCode else {
            return false
        }

        // Clear the code after successful verification
        clearRecoveryCode()

        // Reset lockout and failed attempts
        failedAttempts = 0
        lockoutEndTime = nil
        saveFailedAttempts()
        UserDefaults.standard.removeObject(forKey: Self.lockoutEndKey)

        return true
    }

    /// Reset PIN after recovery verification (call this after verifyRecoveryCode returns true)
    func resetPINAfterRecovery(_ newPIN: String) throws {
        try setPIN(newPIN)
        unlock()
    }

    private func clearRecoveryCode() {
        UserDefaults.standard.removeObject(forKey: Self.recoveryCodeKey)
        UserDefaults.standard.removeObject(forKey: Self.recoveryCodeExpiryKey)
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometric() async -> Bool {
        guard isBiometricAvailable && isBiometricEnabled else {
            return false
        }

        let context = LAContext()
        context.localizedFallbackTitle = "Use PIN"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock PicSurg to access your secure vault"
            )

            if success {
                await MainActor.run {
                    self.unlock()
                }
            }

            return success
        } catch {
            return false
        }
    }

    // MARK: - Lock/Unlock

    func lock() {
        isAuthenticated = false
        isLocked = true
    }

    func unlock() {
        isAuthenticated = true
        isLocked = false
        failedAttempts = 0
        lockoutEndTime = nil
        saveFailedAttempts()
    }

    // MARK: - Lockout Management

    var isLockedOut: Bool {
        guard let endTime = lockoutEndTime else { return false }
        return Date() < endTime
    }

    var lockoutRemainingSeconds: Int {
        guard let endTime = lockoutEndTime else { return 0 }
        return max(0, Int(endTime.timeIntervalSinceNow))
    }

    private func checkAndApplyLockout() {
        // Progressive lockout: 1min after 5, 5min after 8, 15min after 10, 1hr after 15
        let lockoutDuration: TimeInterval
        switch failedAttempts {
        case 5...7:
            lockoutDuration = 60 // 1 minute
        case 8...9:
            lockoutDuration = 300 // 5 minutes
        case 10...14:
            lockoutDuration = 900 // 15 minutes
        case 15...:
            lockoutDuration = 3600 // 1 hour
        default:
            lockoutDuration = 0
        }

        if lockoutDuration > 0 {
            lockoutEndTime = Date().addingTimeInterval(lockoutDuration)
            saveLockoutEnd()
        }
    }

    private func checkLockoutStatus() {
        if let endTimeInterval = UserDefaults.standard.object(forKey: Self.lockoutEndKey) as? TimeInterval {
            let endTime = Date(timeIntervalSince1970: endTimeInterval)
            if Date() < endTime {
                lockoutEndTime = endTime
            } else {
                lockoutEndTime = nil
                UserDefaults.standard.removeObject(forKey: Self.lockoutEndKey)
            }
        }
    }

    private func loadFailedAttempts() {
        failedAttempts = UserDefaults.standard.integer(forKey: Self.failedAttemptsKey)
    }

    private func saveFailedAttempts() {
        UserDefaults.standard.set(failedAttempts, forKey: Self.failedAttemptsKey)
    }

    private func saveLockoutEnd() {
        if let endTime = lockoutEndTime {
            UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: Self.lockoutEndKey)
        }
    }
}
