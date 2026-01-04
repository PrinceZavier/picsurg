import Foundation
import CryptoKit

/// Service for encrypting and decrypting data using AES-256-GCM
final class CryptoService {

    enum CryptoError: Error {
        case keyGenerationFailed
        case encryptionFailed
        case decryptionFailed
        case invalidData
    }

    // Keychain key for storing the encryption key
    private static let encryptionKeyTag = "com.picsurg.vault.encryptionKey"

    // MARK: - Key Management

    /// Get existing key or generate a new one
    static func getOrCreateKey() throws -> SymmetricKey {
        // Try to retrieve existing key
        if let keyData = try? KeychainService.retrieve(forKey: encryptionKeyTag) {
            return SymmetricKey(data: keyData)
        }

        // Generate new key
        let newKey = SymmetricKey(size: .bits256)

        // Store in Keychain
        let keyData = newKey.withUnsafeBytes { Data($0) }
        try KeychainService.save(data: keyData, forKey: encryptionKeyTag)

        return newKey
    }

    /// Check if encryption key exists
    static var hasEncryptionKey: Bool {
        KeychainService.exists(forKey: encryptionKeyTag)
    }

    /// Delete encryption key (WARNING: vault data will be unrecoverable)
    static func deleteKey() throws {
        try KeychainService.delete(forKey: encryptionKeyTag)
    }

    // MARK: - Encryption / Decryption

    /// Encrypt data using AES-256-GCM
    /// - Parameter data: The plaintext data to encrypt
    /// - Returns: The encrypted data (nonce + ciphertext + tag combined)
    static func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()

        do {
            let sealedBox = try AES.GCM.seal(data, using: key)

            // Combine nonce + ciphertext + tag into single Data
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed
            }

            return combined
        } catch {
            throw CryptoError.encryptionFailed
        }
    }

    /// Decrypt data using AES-256-GCM
    /// - Parameter encryptedData: The encrypted data (nonce + ciphertext + tag combined)
    /// - Returns: The decrypted plaintext data
    static func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateKey()

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw CryptoError.decryptionFailed
        }
    }

    // MARK: - Convenience Methods for Images

    /// Encrypt image data
    static func encryptImage(_ imageData: Data) throws -> Data {
        try encrypt(imageData)
    }

    /// Decrypt image data
    static func decryptImage(_ encryptedData: Data) throws -> Data {
        try decrypt(encryptedData)
    }
}
