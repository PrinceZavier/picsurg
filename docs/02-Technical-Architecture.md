# PicSurg - Technical Architecture Document

**Version:** 1.0
**Last Updated:** January 2026
**Status:** Draft

---

## 1. Overview

This document describes the technical architecture for PicSurg, an iOS application for identifying and securing surgical photographs.

### Technology Stack

| Layer | Technology |
|-------|------------|
| Platform | iOS 16+ (Swift/SwiftUI) |
| UI Framework | SwiftUI |
| ML Training | Apple Create ML |
| ML Runtime | Core ML |
| Photo Access | PhotoKit (Photos framework) |
| Security | CryptoKit, LocalAuthentication |
| Storage | FileManager (encrypted files), UserDefaults |
| Background Tasks | BackgroundTasks framework |

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PicSurg App                               │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   SwiftUI    │  │   SwiftUI    │  │   SwiftUI    │          │
│  │  Onboarding  │  │    Home      │  │    Vault     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│  ┌──────┴─────────────────┴─────────────────┴───────┐          │
│  │              View Models (ObservableObject)       │          │
│  └──────────────────────┬────────────────────────────┘          │
│                         │                                        │
│  ┌──────────────────────┴────────────────────────────┐          │
│  │                   Services Layer                   │          │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │          │
│  │  │   Photo     │ │     ML      │ │   Vault     │  │          │
│  │  │  Service    │ │   Service   │ │  Service    │  │          │
│  │  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘  │          │
│  │         │               │               │         │          │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐  │          │
│  │  │    Auth     │ │   Crypto    │ │  Storage    │  │          │
│  │  │  Service    │ │   Service   │ │  Service    │  │          │
│  │  └─────────────┘ └─────────────┘ └─────────────┘  │          │
│  └───────────────────────────────────────────────────┘          │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  iOS Frameworks                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ PhotoKit │ │ Core ML  │ │CryptoKit │ │LocalAuth │            │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### Component Summary

| Component | Purpose |
|-----------|---------|
| **Photo Service** | Accesses iOS Photo Library to fetch and delete photos |
| **ML Service** | Runs the trained model to classify photos as surgical or not |
| **Vault Service** | Manages the secure storage area (add, list, retrieve, delete photos) |
| **Auth Service** | Handles Face ID, Touch ID, and PIN authentication |
| **Crypto Service** | Encrypts photos before storage, decrypts when viewing (AES-256) |
| **Storage Service** | Low-level file system operations for the encrypted vault |

---

## 3. Project Structure

```
PicSurg/
├── PicSurgApp.swift              # App entry point
├── Info.plist                     # App configuration
│
├── Models/
│   ├── Photo.swift               # Photo data model
│   ├── VaultPhoto.swift          # Secured photo model
│   ├── ScanResult.swift          # ML scan result model
│   └── AppSettings.swift         # User preferences
│
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── PermissionsView.swift
│   │   └── PINSetupView.swift
│   │
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ScanProgressView.swift
│   │
│   ├── Review/
│   │   ├── ReviewView.swift
│   │   ├── PhotoGridView.swift
│   │   └── PhotoDetailView.swift
│   │
│   ├── Vault/
│   │   ├── VaultView.swift
│   │   ├── VaultGridView.swift
│   │   └── SecurePhotoView.swift
│   │
│   ├── Settings/
│   │   └── SettingsView.swift
│   │
│   └── Components/
│       ├── AuthenticationView.swift
│       ├── LoadingOverlay.swift
│       └── PhotoThumbnail.swift
│
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── HomeViewModel.swift
│   ├── ReviewViewModel.swift
│   ├── VaultViewModel.swift
│   └── SettingsViewModel.swift
│
├── Services/
│   ├── PhotoService.swift        # Photo library access
│   ├── MLService.swift           # ML classification
│   ├── VaultService.swift        # Secure storage management
│   ├── AuthService.swift         # Biometric/PIN auth
│   ├── CryptoService.swift       # Encryption/decryption
│   ├── StorageService.swift      # File system operations
│   └── BackgroundScanService.swift # Background task handling
│
├── ML/
│   └── SurgicalPhotoClassifier.mlmodel  # Trained model
│
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
│
└── Tests/
    ├── MLServiceTests.swift
    ├── CryptoServiceTests.swift
    └── VaultServiceTests.swift
```

---

## 4. Core Components

### 4.1 Photo Service

Handles all interactions with the iOS Photo Library using PhotoKit.

```swift
// PhotoService.swift - Key responsibilities
class PhotoService {
    // Request photo library authorization
    func requestAuthorization() async -> PHAuthorizationStatus

    // Fetch all photos from camera roll
    func fetchAllPhotos() -> [PHAsset]

    // Fetch photo image data for ML processing
    func loadImageData(for asset: PHAsset) async -> Data?

    // Delete photo from library (after securing)
    func deletePhoto(_ asset: PHAsset) async throws
}
```

**Key Considerations:**
- Request `.readWrite` authorization for full access
- Use `PHCachingImageManager` for efficient thumbnail loading
- Fetch photos in batches to manage memory
- Handle authorization state changes

### 4.2 ML Service

Manages the Core ML model for surgical photo classification.

```swift
// MLService.swift - Key responsibilities
class MLService {
    private let model: SurgicalPhotoClassifier

    // Classify a single photo
    func classifyPhoto(_ imageData: Data) async -> ClassificationResult

    // Batch classify multiple photos
    func scanPhotos(_ assets: [PHAsset],
                    progress: (Float) -> Void) async -> [ScanResult]

    // Result includes confidence score
    struct ClassificationResult {
        let isSurgical: Bool
        let confidence: Float  // 0.0 to 1.0
    }
}
```

**ML Model Details:**
- **Input**: 299x299 RGB image
- **Output**: Binary classification (surgical/non-surgical) with confidence
- **Model File**: `PicSurge V1 1.mlmodel` (already trained)
- **Performance**: ~50ms per image on modern iPhones

### 4.3 Vault Service

Manages the secure storage of photos.

```swift
// VaultService.swift - Key responsibilities
class VaultService {
    // Add photo to vault (encrypt and store)
    func addPhoto(_ imageData: Data,
                  originalAsset: PHAsset) async throws -> VaultPhoto

    // Retrieve decrypted photo
    func getPhoto(id: UUID) async throws -> Data

    // List all vault photos (metadata only)
    func listPhotos() -> [VaultPhoto]

    // Delete from vault
    func deletePhoto(id: UUID) throws

    // Export photo (decrypt for sharing)
    func exportPhoto(id: UUID) async throws -> Data
}
```

**Storage Structure:**
```
Documents/
└── Vault/
    ├── metadata.json.encrypted    # Vault index
    └── photos/
        ├── {uuid1}.encrypted      # Encrypted photo data
        ├── {uuid2}.encrypted
        └── ...
```

### 4.4 Auth Service

Handles all authentication (Face ID, Touch ID, PIN).

```swift
// AuthService.swift - Key responsibilities
class AuthService {
    // Check if device supports biometrics
    var biometricType: BiometricType  // .faceID, .touchID, .none

    // Authenticate user
    func authenticate(reason: String) async -> Bool

    // PIN management
    func setPIN(_ pin: String) throws
    func verifyPIN(_ pin: String) -> Bool
    func changePIN(from old: String, to new: String) throws

    // Lock state
    var isLocked: Bool
    func lock()
    func unlock()
}
```

**Security Implementation:**
- PIN stored in Keychain (not UserDefaults)
- Use `LAContext` for biometric authentication
- Require authentication on every app foreground
- Implement attempt limiting with exponential backoff

### 4.5 Crypto Service

Handles all encryption/decryption operations.

```swift
// CryptoService.swift - Key responsibilities
class CryptoService {
    // Generate encryption key (stored in Keychain)
    func generateKey() throws -> SymmetricKey

    // Encrypt data
    func encrypt(_ data: Data) throws -> Data

    // Decrypt data
    func decrypt(_ encryptedData: Data) throws -> Data
}
```

**Encryption Approach:**
- AES-256-GCM via CryptoKit
- Symmetric key stored in iOS Keychain
- Key protected by device passcode
- Each photo encrypted individually

---

## 5. Data Flow Diagrams

### 5.1 Photo Scanning Flow

```
┌────────┐     ┌─────────────┐     ┌────────────┐     ┌──────────┐
│  User  │────▶│ HomeView    │────▶│PhotoService│────▶│  Photos  │
│        │     │ taps Scan   │     │ fetchAll() │     │ Library  │
└────────┘     └─────────────┘     └────────────┘     └──────────┘
                     │                   │
                     │                   ▼
                     │           ┌──────────────┐
                     │           │ [PHAsset]    │
                     │           │ array        │
                     │           └──────────────┘
                     │                   │
                     ▼                   ▼
              ┌─────────────┐     ┌────────────┐
              │  Progress   │◀────│ MLService  │
              │  Updates    │     │ classify() │
              └─────────────┘     └────────────┘
                     │                   │
                     │                   ▼
                     │           ┌──────────────┐
                     │           │ [ScanResult] │
                     │           │ with scores  │
                     │           └──────────────┘
                     │                   │
                     ▼                   ▼
              ┌─────────────────────────────────┐
              │        ReviewView               │
              │  Shows identified surgical      │
              │  photos for user approval       │
              └─────────────────────────────────┘
```

### 5.2 Photo Securing Flow

```
┌────────┐     ┌─────────────┐     ┌────────────┐
│  User  │────▶│ ReviewView  │────▶│PhotoService│
│approves│     │ approve()   │     │loadImage() │
└────────┘     └─────────────┘     └────────────┘
                     │                   │
                     │                   ▼
                     │           ┌──────────────┐
                     │           │ Image Data   │
                     │           │ (full res)   │
                     │           └──────────────┘
                     │                   │
                     ▼                   ▼
              ┌─────────────┐     ┌────────────┐
              │VaultService │◀────│CryptoService│
              │ addPhoto()  │     │ encrypt()  │
              └─────────────┘     └────────────┘
                     │                   │
                     │                   ▼
                     │           ┌──────────────┐
                     │           │ Encrypted    │
                     │           │ file saved   │
                     │           └──────────────┘
                     │                   │
                     ▼                   ▼
              ┌─────────────┐     ┌────────────┐
              │PhotoService │     │  Photos    │
              │deletePhoto()│────▶│  Library   │
              └─────────────┘     └────────────┘
```

### 5.3 Vault Access Flow

```
┌────────┐     ┌─────────────┐     ┌────────────┐
│  User  │────▶│ Open App /  │────▶│AuthService │
│        │     │ Vault Tab   │     │authenticate│
└────────┘     └─────────────┘     └────────────┘
                                         │
                     ┌───────────────────┴────────────────┐
                     ▼                                    ▼
              ┌─────────────┐                    ┌─────────────┐
              │  Face ID /  │                    │  PIN Entry  │
              │  Touch ID   │                    │  Fallback   │
              └─────────────┘                    └─────────────┘
                     │                                    │
                     └───────────────────┬────────────────┘
                                         ▼
                              ┌─────────────────┐
                              │   Authenticated │
                              └────────┬────────┘
                                       │
                     ┌─────────────────┴─────────────────┐
                     ▼                                   ▼
              ┌─────────────┐                   ┌─────────────┐
              │VaultService │                   │CryptoService│
              │ listPhotos()│                   │ (ready)     │
              └─────────────┘                   └─────────────┘
                     │
                     ▼
              ┌─────────────┐
              │  VaultView  │
              │ shows grid  │
              └─────────────┘
                     │
                     │ User taps photo
                     ▼
              ┌─────────────┐     ┌────────────┐
              │VaultService │────▶│CryptoService│
              │ getPhoto()  │     │ decrypt()  │
              └─────────────┘     └────────────┘
                     │
                     ▼
              ┌─────────────┐
              │SecurePhoto  │
              │   View      │
              └─────────────┘
```

---

## 6. Machine Learning Architecture

### 6.1 Existing Trained Model

**Model Details:**
- **File**: `PicSurge V1 1.mlmodel`
- **Location**: `PicSurge V1.mlproj/Models/`
- **Type**: Image Classifier (trained via Create ML)
- **Created**: January 1, 2026

**To integrate into Xcode project:**
1. Drag `PicSurge V1 1.mlmodel` into Xcode project navigator
2. Ensure "Copy items if needed" is checked
3. Add to app target
4. Xcode auto-generates Swift class for model access

**Future retraining (if needed):**
- Open `PicSurge V1.mlproj` in Create ML
- Add more training images to improve accuracy
- Re-export updated `.mlmodel` file

### 6.2 Model Integration (Core ML)

```swift
// Generated from .mlmodel file
class SurgicalPhotoClassifier {
    // Input: Image (299x299 pixels)
    // Output: Classification label + confidence dictionary

    func prediction(image: CVPixelBuffer) throws -> SurgicalPhotoClassifierOutput
}

// Wrapper for easier use
class MLService {
    private lazy var model: SurgicalPhotoClassifier = {
        try! SurgicalPhotoClassifier(configuration: MLModelConfiguration())
    }()

    func classify(image: UIImage) -> (isSurgical: Bool, confidence: Float) {
        // 1. Resize image to 299x299
        // 2. Convert to CVPixelBuffer
        // 3. Run prediction
        // 4. Return result with confidence
    }
}
```

### 6.3 Classification Thresholds

| Confidence | Action |
|------------|--------|
| ≥ 0.80 | Mark as surgical (high confidence) |
| 0.50 - 0.79 | Mark as surgical (review recommended) |
| < 0.50 | Not surgical |

---

## 7. Security Architecture

### 7.1 Threat Model

| Threat | Mitigation |
|--------|------------|
| Unauthorized app access | Biometric + PIN authentication |
| Data theft (device stolen) | AES-256 encryption at rest |
| Memory dump attack | Clear sensitive data from memory after use |
| Backup extraction | Exclude vault from iCloud/iTunes backup |
| Screen capture | Disable screenshots in vault view |
| Shoulder surfing | Quick lock on background |

### 7.2 Encryption Implementation

```swift
// CryptoService implementation
import CryptoKit

class CryptoService {
    private let keyTag = "com.picsurg.vault.key"

    // Get or create encryption key
    private func getKey() throws -> SymmetricKey {
        if let keyData = KeychainService.retrieve(keyTag) {
            return SymmetricKey(data: keyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        try KeychainService.store(newKey.rawRepresentation, tag: keyTag)
        return newKey
    }

    func encrypt(_ data: Data) throws -> Data {
        let key = try getKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }

    func decrypt(_ data: Data) throws -> Data {
        let key = try getKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
```

### 7.3 Keychain Usage

| Item | Protection Class | Description |
|------|------------------|-------------|
| Encryption Key | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | AES-256 key for vault encryption |
| PIN Hash | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | Hashed PIN for verification |

---

## 8. Background Processing

### 8.1 Background Scan Implementation

```swift
// BackgroundScanService.swift
import BackgroundTasks

class BackgroundScanService {
    static let taskIdentifier = "com.picsurg.photoscan"

    func registerTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundScan(task: task as! BGProcessingTask)
        }
    }

    func scheduleBackgroundScan() {
        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false // Can run on battery

        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleBackgroundScan(task: BGProcessingTask) {
        // 1. Fetch new photos since last scan
        // 2. Classify each photo
        // 3. Store results for review
        // 4. Send local notification if surgical photos found
        // 5. Schedule next scan

        task.setTaskCompleted(success: true)
    }
}
```

**Important Notes:**
- Background tasks are not guaranteed to run
- iOS controls when background tasks execute
- User must have app in background (not force-quit)
- For MVP, manual scanning is more reliable

---

## 9. State Management

### 9.1 App State

```swift
// AppState.swift
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isOnboarded = false
    @Published var pendingReviewCount = 0

    // Persisted to UserDefaults
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("lastScanDate") var lastScanDate: Date?
    @AppStorage("autoScanEnabled") var autoScanEnabled = false
}
```

### 9.2 View Model Pattern

```swift
// Example: HomeViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var scanProgress: Float = 0
    @Published var scanResults: [ScanResult] = []
    @Published var error: Error?

    private let photoService: PhotoService
    private let mlService: MLService

    func startScan() async {
        isScanning = true
        defer { isScanning = false }

        do {
            let photos = photoService.fetchAllPhotos()
            scanResults = await mlService.scanPhotos(photos) { progress in
                Task { @MainActor in
                    self.scanProgress = progress
                }
            }
        } catch {
            self.error = error
        }
    }
}
```

---

## 10. Testing Strategy

### 10.1 Unit Tests

| Component | Test Focus |
|-----------|------------|
| CryptoService | Encrypt/decrypt round-trip, key generation |
| MLService | Classification accuracy, batch processing |
| VaultService | Add/retrieve/delete operations |
| AuthService | PIN verification, attempt limiting |

### 10.2 Integration Tests

- Full scan → review → secure flow
- Authentication flow with biometric fallback
- Background scan scheduling

### 10.3 UI Tests

- Onboarding flow completion
- Vault navigation and photo viewing
- Settings changes

---

## 11. Dependencies

| Dependency | Purpose | Type |
|------------|---------|------|
| SwiftUI | UI Framework | Apple Framework |
| PhotoKit | Photo Library Access | Apple Framework |
| Core ML | ML Model Runtime | Apple Framework |
| CryptoKit | Encryption | Apple Framework |
| LocalAuthentication | Biometric Auth | Apple Framework |
| BackgroundTasks | Background Processing | Apple Framework |

**Note:** All dependencies are first-party Apple frameworks. No third-party dependencies required for MVP.

---

## 12. Performance Considerations

### Memory Management
- Load photo thumbnails lazily
- Release full-resolution images after processing
- Use autoreleasepool for batch operations

### Battery Optimization
- Batch ML operations
- Defer non-critical work
- Respect Low Power Mode

### Storage Efficiency
- Compress photos appropriately before encryption
- Clean up temporary files
- Implement vault size monitoring
