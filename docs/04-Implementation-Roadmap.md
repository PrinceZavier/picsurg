# PicSurg - Implementation Roadmap

**Version:** 1.0
**Last Updated:** January 2026
**Status:** MVP Complete

---

## 1. Overview

This roadmap breaks down PicSurg development into phases. The goal is to get a working end-to-end MVP as quickly as possible, then iterate.

**Note**: ML model already trained (`PicSurgeV1.mlmodel`) - Phase 0 is simplified.

---

## 2. Phase Summary

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 0** | Project Setup | ✅ Complete |
| **Phase 1** | Core Security | ✅ Complete |
| **Phase 2** | Photo Scanning | ✅ Complete |
| **Phase 3** | Integration | ✅ Complete |
| **Phase 4** | Polish | ✅ Complete |
| **Future** | Enhancements | Planned |

---

## 3. Phase 0: Project Setup ✅

**Goal**: Get Xcode project ready with existing ML model.

### Existing Asset
- **Trained Model**: `PicSurgeV1.mlmodel`
- **Type**: Image Classifier (Surgical / NonSurgical)
- **Created**: January 2026

### Tasks

#### 0.1 Development Environment
- [x] Verify Xcode is up to date (16.0+)
- [x] Create new iOS App project in Xcode
  - Product Name: PicSurg
  - Interface: SwiftUI
  - Language: Swift
  - Minimum iOS: 16.0
- [x] Set up project folder structure (see Architecture doc)
- [x] Configure app capabilities:
  - Photo Library access
  - Face ID usage

#### 0.2 Integrate Existing ML Model
- [x] Copy `PicSurgeV1.mlmodel` from ML project to Xcode project
- [x] Add to Xcode target (drag into project navigator)
- [x] Verify Xcode generates Swift class for model
- [x] Test model loads without errors

#### 0.3 Configure Info.plist
- [x] Add `NSPhotoLibraryUsageDescription`
- [x] Add `NSFaceIDUsageDescription`

### Deliverables
- ✅ Xcode project created and compiles
- ✅ Existing ML model integrated
- ✅ Permissions configured

---

## 4. Phase 1: Core Security ✅

**Goal**: Build authentication and encrypted storage foundation.

### Tasks

#### 1.1 Keychain Service
- [x] Create `KeychainService.swift`
- [x] Implement key storage/retrieval
- [x] Implement PIN hash storage
- [x] Test Keychain operations

#### 1.2 Crypto Service
- [x] Create `CryptoService.swift`
- [x] Implement key generation (first launch)
- [x] Implement AES-256-GCM encryption
- [x] Implement AES-256-GCM decryption
- [x] Test encrypt/decrypt round-trip

#### 1.3 Auth Service
- [x] Create `AuthService.swift`
- [x] Implement Face ID / Touch ID authentication
- [x] Implement PIN setup
- [x] Implement PIN verification
- [x] Implement failed attempt lockout
- [x] Test auth flows (tested on iPhone 11)

#### 1.4 Vault Service (Basic)
- [x] Create `VaultService.swift`
- [x] Create vault directory structure
- [x] Implement encrypted file write
- [x] Implement encrypted file read
- [x] Implement vault metadata index
- [x] Exclude vault from backups

#### 1.5 Authentication UI
- [x] Create `LockScreenView.swift` - Lock screen with Face ID + PIN
- [x] Create `PINSetupView.swift` - First-time PIN creation
- [x] Create `NumberButton.swift` - PIN input pad
- [x] Wire up auth flow in app entry

### Deliverables
- ✅ App launches to lock screen
- ✅ Face ID authentication works (tested on iPhone 11)
- ✅ PIN setup and verification works
- ✅ Can encrypt/decrypt test data

---

## 5. Phase 2: Photo Scanning ✅

**Goal**: Access camera roll and classify photos with ML.

### Tasks

#### 2.1 Photo Service
- [x] Create `PhotoService.swift`
- [x] Implement photo library authorization request
- [x] Implement fetch all photos
- [x] Implement thumbnail loading (efficient)
- [x] Implement full-resolution image loading
- [x] Handle authorization denied state

#### 2.2 ML Service
- [x] Create `MLService.swift`
- [x] Load existing `PicSurgeV1` Core ML model
- [x] Implement single photo classification
- [x] Implement batch classification with progress
- [x] Return confidence scores with labels

**Technical Note**: ML model configured with `computeUnits = .cpuOnly` for compatibility. Classification runs on background thread using `Task.detached` to avoid continuation issues.

#### 2.3 Scan Models
- [x] Create `ScanResult` struct (in MLService)
- [x] Photo wrapper using PHAsset identifiers

#### 2.4 Scan UI
- [x] Create `HomeView.swift` - main screen with Scan button
- [x] Add scan limit picker (50, 100, 250, 500, 1000 photos)
- [x] Implement scan initiation
- [x] Show scan progress
- [x] Navigate to results when complete

### Deliverables
- ✅ Can request photo library access
- ✅ Scan button triggers ML classification
- ✅ Progress shown during scan
- ✅ Results ready for review screen

---

## 6. Phase 3: Integration ✅

**Goal**: Complete end-to-end flow from scan to secure storage.

### Tasks

#### 3.1 Review UI
- [x] Create `ReviewView.swift` - grid of identified surgical photos
- [x] Create `PhotoThumbnailView.swift` - single thumbnail with selection
- [x] Show confidence score per photo
- [x] Implement select/deselect individual photos
- [x] Implement "Select All" / "Deselect All"
- [x] Implement "Secure Selected" action

#### 3.2 Secure Photo Flow
- [x] Load full-resolution image for approved photos
- [x] Encrypt and save to vault
- [x] Update vault metadata index
- [x] Bulk delete from camera roll (single iOS confirmation)
- [x] Show success/failure feedback

#### 3.3 Vault UI
- [x] Create `VaultView.swift` - grid of secured photos
- [x] Create `SecurePhotoView.swift` - full-screen photo viewer
- [x] Implement photo decryption on view
- [x] Implement delete from vault
- [x] Show photo count and dates
- [x] Pinch-to-zoom and double-tap zoom

#### 3.4 Navigation
- [x] Create tab bar navigation (Home, Vault, Settings)
- [x] Wire up all view transitions
- [x] Handle empty states

#### 3.5 Onboarding
- [x] Create `OnboardingView.swift` - welcome flow
- [x] Request photo access with explanation
- [x] Guide user through PIN setup
- [x] Prompt for biometric enrollment
- [x] Mark onboarding complete

### Deliverables
- ✅ Full flow works: scan → review → approve → secure → delete
- ✅ Vault shows secured photos
- ✅ Photos viewable after decryption
- ✅ Onboarding guides new users

---

## 7. Phase 4: Polish ✅

**Goal**: Improve reliability, handle edge cases, enhance UI.

### Tasks

#### 4.1 Error Handling ✅
- [x] Handle photo library access denied → Guide to Settings
- [x] Handle biometric not available → Use PIN only
- [x] Handle encryption failures → Don't delete original, show error
- [x] Handle storage full → Check before securing, show error
- [x] Show user-friendly error messages via alerts

**Implementation**: Added `AppError` struct with predefined error types. Each view has local error state with alert modifiers.

#### 4.2 Edge Cases ✅
See detailed explanations in [05-Technical-Decisions.md](05-Technical-Decisions.md)

| Edge Case | Solution |
|-----------|----------|
| Zero surgical photos found | "No Surgical Photos Found" alert with suggestions |
| Large photo libraries (8000+) | Scan limit picker prevents crashes (50-1000) |
| Empty vault state | Step-by-step instructions shown |
| Low storage space | Pre-check before securing, ~5MB per photo estimate |
| Memory pressure during scan | Monitor memory usage, stop gracefully if 25% threshold exceeded |
| Empty photo library | "No photos found" error message |
| Various photo formats | PhotoKit handles HEIC, JPEG, PNG automatically |
| App interrupted during secure | Photos only deleted after successful vault save |
| ML model fails in simulator | Mock results for UI testing |

#### 4.3 UI Polish
- [ ] Add app icon
- [ ] Add launch screen
- [ ] Improve visual design
- [x] Dark Mode support (uses system colors)
- [ ] Add haptic feedback
- [x] Add loading states

#### 4.4 Settings ✅
- [x] Create `SettingsView.swift`
- [x] Change PIN option with `ChangePINView`
- [x] Toggle biometric on/off
- [x] View vault statistics (count, size)
- [x] Photo Access section (view status, link to Settings)
- [x] Delete all vault data option
- [x] Reset app option
- [x] About section (version, privacy, help links)

#### 4.5 Testing ✅
- [x] Test on physical device (iPhone 11, iOS 18.6.2)
- [x] Test with real surgical photos
- [x] Test authentication (Face ID works)
- [x] Test with large photo library (8000+ photos)
- [x] Verify encryption working

### Deliverables
- ✅ App handles errors gracefully
- ✅ Settings fully functional
- ✅ Ready for personal use

---

## 8. Future Enhancements (Post-MVP)

### 8.1 Batch Scanning for Large Libraries
GitHub Issue: #31
- [ ] Remember scan progress across sessions
- [ ] "Scan Next 1000" functionality
- [ ] Date range picker for targeted scanning
- [ ] Progress tracker showing library coverage

### 8.2 Background Scanning
- [ ] Implement BGProcessingTask
- [ ] Schedule periodic scans
- [ ] Local notification when photos found
- [ ] Battery-efficient implementation

### 8.3 Manual Photo Addition
- [ ] "Add to Vault" option in review
- [ ] Browse and select any photo
- [ ] Useful for photos ML missed

### 8.4 Export & Sharing
- [ ] Export single photo (decrypted)
- [ ] Share via AirDrop
- [ ] Share via secure email
- [ ] Audit log for exports

### 8.5 Organization Features
- [ ] Create folders/albums in vault
- [ ] Tag photos
- [ ] Search by date
- [ ] Sort options

### 8.6 Cloud Backup (Requires BAA)
- [ ] End-to-end encrypted backup
- [ ] iCloud or custom server
- [ ] Restore to new device
- [ ] HIPAA BAA with provider

### 8.7 Model Improvement
- [ ] Collect user corrections (false positives/negatives)
- [ ] Retrain model periodically
- [ ] Improve accuracy over time

---

## 9. Development Notes

### Key Technical Decisions

1. **ML Model Compatibility**: Use `config.computeUnits = .cpuOnly` to avoid "inference context" errors on some devices.

2. **Async Classification**: Use `Task.detached` for ML classification to prevent "continuation resumed more than once" errors.

3. **Simulator Detection**: Use `#if targetEnvironment(simulator)` to provide mock ML results for UI testing.

4. **Bulk Deletion**: Collect all photos to delete, then call `PHPhotoLibrary.performChanges` once for single iOS confirmation dialog.

5. **Memory Management**: Monitor `task_vm_info.phys_footprint` during scan and stop gracefully if exceeding 25% of physical memory.

### Your Trained Model

Your model `PicSurgeV1.mlmodel` is integrated and working:
- Labels: "Surgical", "NonSurgical"
- Tested successfully on iPhone 11
- Returns confidence scores (0.0 - 1.0)

### Testing Without Apple Developer Account

Without a paid developer account:
- Can run on simulator (but ML may not work fully)
- Can run on your physical device for 7 days (free provisioning)
- Must re-install every 7 days
- Cannot use TestFlight or App Store

---

## 10. Success Criteria

### MVP Complete ✅

- [x] App launches and requires authentication
- [x] Can set up PIN on first launch
- [x] Face ID / Touch ID works for unlock
- [x] Can scan photo library for surgical images
- [x] Your trained model correctly identifies surgical photos
- [x] Can review and select photos to secure
- [x] Selected photos encrypted and saved to vault
- [x] Original photos deleted from camera roll
- [x] Vault displays secured photos
- [x] Can view individual photos in vault
- [x] App locks when backgrounded

### Stretch Goals:

- [ ] Background scanning works
- [x] Settings fully implemented
- [ ] Polished UI with Dark Mode and app icon
- [x] Comprehensive error handling
