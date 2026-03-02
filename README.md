# PicSurg

An iOS app that uses machine learning to automatically identify surgical/operative photos in your camera roll and securely stores them in an encrypted, biometric-protected vault — helping healthcare providers stay HIPAA-compliant.

## Features

### ML-Powered Scanning
- **Automatic Detection** — Trained Core ML model identifies surgical photos with confidence scores
- **Batch Processing** — Scans photos in batches of 100 to handle large libraries (8,000+ tested)
- **Incremental Scanning** — Tracks scanned photos across sessions, only processes new ones
- **Shazam-Style UI** — Tap the spinning logo to scan, with real-time progress

### Secure Vault
- **AES-256-GCM Encryption** — All photos encrypted at rest using CryptoKit
- **Apple Photos-Style UI** — Grid view with multi-select, share, and batch delete
- **Full-Screen Viewer** — Pinch-to-zoom, double-tap zoom
- **Share & Export** — AirDrop, iMessage, email, and more via iOS Share Sheet
- **Restore to Camera Roll** — Return photos to your photo library if needed

### Authentication & Security
- **Face ID / Touch ID** — Biometric unlock with PIN fallback
- **6-Digit PIN** — Secured with PBKDF2-HMAC-SHA256 (100K iterations) and constant-time comparison
- **PIN Recovery** — Recovery email with 6-digit code (15-minute expiry)
- **Progressive Lockout** — 1 min, 5 min, 15 min, 1 hour after failed attempts
- **Auto-Wipe** — Optional data erasure after configurable failed PIN attempts (10-25)
- **Session Management** — Configurable grace period on background and inactivity auto-lock

### Manual Photo Addition
- **Photo Picker** — Manually select up to 50 photos to secure in the vault
- **Auto-Remove** — Selected photos encrypted and removed from camera roll

### Scan Reminders
- **Daily / Weekly Notifications** — Configurable reminders to scan for surgical photos
- **Custom Time & Day** — Pick your preferred reminder time and weekday

### Other
- **Guided Onboarding** — 5-step setup (welcome, permissions, PIN, recovery email, biometrics)
- **Dark Mode** — Full dark mode support using system colors
- **Haptic Feedback** — Tactile responses throughout the app
- **No Third-Party Dependencies** — Built entirely with Apple frameworks

## Tech Stack

| Layer | Technology |
|-------|------------|
| Platform | iOS 16+ (Swift / SwiftUI) |
| ML | Core ML (Create ML Image Classifier) |
| Security | CryptoKit (AES-256-GCM), LocalAuthentication, Keychain |
| Photos | PhotoKit |
| Notifications | UserNotifications |

## Project Structure

```
PicSurg/
├── Models/          # AppState, data models
├── Views/
│   ├── Home/        # Shazam-style scan button, scan progress
│   ├── Review/      # Photo review grid with confidence scores
│   ├── Vault/       # Encrypted photo gallery, share, multi-select
│   ├── Settings/    # Security, reminders, storage, about
│   ├── Onboarding/  # 5-step guided setup
│   └── Components/  # Lock screen, shared UI
├── Services/
│   ├── AuthService      # Biometric, PIN, recovery, auto-wipe
│   ├── MLService        # Core ML classification
│   ├── VaultService     # Encrypted storage CRUD
│   ├── CryptoService    # AES-256-GCM encrypt/decrypt
│   ├── PhotoService     # PhotoKit integration
│   ├── ReminderService  # Scan reminder notifications
│   └── KeychainService  # Secure key/PIN storage
├── Theme/           # Colors, typography, haptics, button styles
└── ML/              # Trained surgical photo classifier model
```

## Status

Active development — MVP complete with ongoing enhancements.
