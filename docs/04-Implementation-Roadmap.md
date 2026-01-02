# PicSurg - Implementation Roadmap

**Version:** 1.0
**Last Updated:** January 2026
**Status:** Draft

---

## 1. Overview

This roadmap breaks down PicSurg development into phases. The goal is to get a working end-to-end MVP as quickly as possible, then iterate.

**Note**: ML model already trained (`PicSurge V1 1.mlmodel`) - Phase 0 is simplified.

---

## 2. Phase Summary

| Phase | Focus | Outcome |
|-------|-------|---------|
| **Phase 0** | Project Setup | Xcode project created, existing ML model integrated |
| **Phase 1** | Core Security | Authentication + encrypted vault working |
| **Phase 2** | Photo Scanning | ML classification of photos working |
| **Phase 3** | Integration | Full flow: scan → review → secure → delete |
| **Phase 4** | Polish | UI improvements, edge cases, testing |
| **Future** | Enhancements | Background scanning, cloud backup, etc. |

---

## 3. Phase 0: Project Setup

**Goal**: Get Xcode project ready with existing ML model.

### Existing Asset
- **Trained Model**: `PicSurge V1.mlproj/Models/PicSurge V1 1.mlmodel`
- **Type**: Image Classifier
- **Created**: January 1, 2026

### Tasks

#### 0.1 Development Environment
- [ ] Verify Xcode is up to date (16.0+)
- [ ] Create new iOS App project in Xcode
  - Product Name: PicSurg
  - Interface: SwiftUI
  - Language: Swift
  - Minimum iOS: 16.0
- [ ] Set up project folder structure (see Architecture doc)
- [ ] Configure app capabilities:
  - Photo Library access
  - Face ID usage

#### 0.2 Integrate Existing ML Model
- [ ] Copy `PicSurge V1 1.mlmodel` from ML project to Xcode project
- [ ] Add to Xcode target (drag into project navigator)
- [ ] Verify Xcode generates Swift class for model
- [ ] Test model loads without errors

#### 0.3 Configure Info.plist
- [ ] Add `NSPhotoLibraryUsageDescription` - "PicSurg needs access to your photos to identify and secure surgical images."
- [ ] Add `NSFaceIDUsageDescription` - "PicSurg uses Face ID to protect your secure vault."

### Deliverables
- Xcode project created and compiles
- Existing ML model integrated
- Permissions configured

---

## 4. Phase 1: Core Security

**Goal**: Build authentication and encrypted storage foundation.

### Tasks

#### 1.1 Keychain Service
- [ ] Create `KeychainService.swift`
- [ ] Implement key storage/retrieval
- [ ] Implement PIN hash storage
- [ ] Test Keychain operations

#### 1.2 Crypto Service
- [ ] Create `CryptoService.swift`
- [ ] Implement key generation (first launch)
- [ ] Implement AES-256-GCM encryption
- [ ] Implement AES-256-GCM decryption
- [ ] Test encrypt/decrypt round-trip

#### 1.3 Auth Service
- [ ] Create `AuthService.swift`
- [ ] Implement Face ID / Touch ID authentication
- [ ] Implement PIN setup
- [ ] Implement PIN verification
- [ ] Implement failed attempt lockout
- [ ] Test auth flows

#### 1.4 Vault Service (Basic)
- [ ] Create `VaultService.swift`
- [ ] Create vault directory structure
- [ ] Implement encrypted file write
- [ ] Implement encrypted file read
- [ ] Implement vault metadata index
- [ ] Exclude vault from backups

#### 1.5 Authentication UI
- [ ] Create `AuthenticationView.swift` - Lock screen with Face ID + PIN
- [ ] Create `PINSetupView.swift` - First-time PIN creation
- [ ] Create `PINEntryView.swift` - PIN input pad
- [ ] Wire up auth flow in app entry

### Deliverables
- App launches to lock screen
- Face ID authentication works
- PIN setup and verification works
- Can encrypt/decrypt test data

---

## 5. Phase 2: Photo Scanning

**Goal**: Access camera roll and classify photos with ML.

### Tasks

#### 2.1 Photo Service
- [ ] Create `PhotoService.swift`
- [ ] Implement photo library authorization request
- [ ] Implement fetch all photos
- [ ] Implement thumbnail loading (efficient)
- [ ] Implement full-resolution image loading
- [ ] Handle authorization denied state

#### 2.2 ML Service
- [ ] Create `MLService.swift`
- [ ] Load existing `PicSurge V1 1` Core ML model
- [ ] Implement single photo classification
- [ ] Implement batch classification with progress
- [ ] Return confidence scores with labels

#### 2.3 Scan Models
- [ ] Create `ScanResult.swift` - photo + classification + confidence
- [ ] Create `Photo.swift` - wrapper around PHAsset

#### 2.4 Scan UI
- [ ] Create `HomeView.swift` - main screen with Scan button
- [ ] Create `ScanProgressView.swift` - progress during scan
- [ ] Implement scan initiation
- [ ] Show scan progress
- [ ] Navigate to results when complete

### Deliverables
- Can request photo library access
- Scan button triggers ML classification using your trained model
- Progress shown during scan
- Results ready for review screen

---

## 6. Phase 3: Integration

**Goal**: Complete end-to-end flow from scan to secure storage.

### Tasks

#### 3.1 Review UI
- [ ] Create `ReviewView.swift` - grid of identified surgical photos
- [ ] Create `PhotoGridView.swift` - reusable photo grid component
- [ ] Create `PhotoThumbnail.swift` - single thumbnail with selection
- [ ] Show confidence score per photo
- [ ] Implement select/deselect individual photos
- [ ] Implement "Approve Selected" action
- [ ] Implement "Reject All" action

#### 3.2 Secure Photo Flow
- [ ] Load full-resolution image for approved photos
- [ ] Encrypt and save to vault
- [ ] Update vault metadata index
- [ ] Delete from camera roll (with confirmation)
- [ ] Show success/failure feedback

#### 3.3 Vault UI
- [ ] Create `VaultView.swift` - grid of secured photos
- [ ] Create `VaultGridView.swift` - browsable vault contents
- [ ] Create `SecurePhotoView.swift` - full-screen photo viewer
- [ ] Implement photo decryption on view
- [ ] Implement delete from vault
- [ ] Show photo count and dates

#### 3.4 Navigation
- [ ] Create tab bar navigation (Home, Vault, Settings)
- [ ] Wire up all view transitions
- [ ] Handle empty states (no photos, empty vault)

#### 3.5 Onboarding
- [ ] Create `OnboardingView.swift` - welcome flow
- [ ] Create `PermissionsView.swift` - request photo access
- [ ] Guide user through PIN setup
- [ ] Prompt for biometric enrollment
- [ ] Mark onboarding complete

### Deliverables
- Full flow works: scan → review → approve → secure → delete
- Vault shows secured photos
- Photos viewable after decryption
- Onboarding guides new users

---

## 7. Phase 4: Polish

**Goal**: Improve reliability, handle edge cases, enhance UI.

### Tasks

#### 4.1 Error Handling
- [ ] Handle photo library access denied
- [ ] Handle biometric not available
- [ ] Handle encryption failures
- [ ] Handle storage full
- [ ] Show user-friendly error messages

#### 4.2 Edge Cases
- [ ] Handle zero surgical photos found
- [ ] Handle very large photo libraries (1000+)
- [ ] Handle app interrupted during secure
- [ ] Handle corrupted vault recovery

#### 4.3 UI Polish
- [ ] Add app icon
- [ ] Add launch screen
- [ ] Improve visual design
- [ ] Add haptic feedback
- [ ] Support Dark Mode
- [ ] Add loading states

#### 4.4 Settings
- [ ] Create `SettingsView.swift`
- [ ] Change PIN option
- [ ] Toggle biometric on/off
- [ ] View vault statistics
- [ ] Delete all vault data option
- [ ] About/Help section

#### 4.5 Testing
- [ ] Test on physical device
- [ ] Test with real surgical photos
- [ ] Test authentication edge cases
- [ ] Test with large photo library
- [ ] Verify encryption working (inspect files)

### Deliverables
- App handles errors gracefully
- Settings fully functional
- Ready for personal use

---

## 8. Future Enhancements (Post-MVP)

### 8.1 Background Scanning
- [ ] Implement BGProcessingTask
- [ ] Schedule periodic scans
- [ ] Local notification when photos found
- [ ] Battery-efficient implementation

### 8.2 Manual Photo Addition
- [ ] "Add to Vault" option in review
- [ ] Browse and select any photo
- [ ] Useful for photos ML missed

### 8.3 Export & Sharing
- [ ] Export single photo (decrypted)
- [ ] Share via AirDrop
- [ ] Share via secure email
- [ ] Audit log for exports

### 8.4 Organization Features
- [ ] Create folders/albums in vault
- [ ] Tag photos
- [ ] Search by date
- [ ] Sort options

### 8.5 Cloud Backup (Requires BAA)
- [ ] End-to-end encrypted backup
- [ ] iCloud or custom server
- [ ] Restore to new device
- [ ] HIPAA BAA with provider

### 8.6 Model Improvement
- [ ] Collect user corrections (false positives/negatives)
- [ ] Retrain model periodically
- [ ] Improve accuracy over time

---

## 9. Development Notes

### Getting Started Quickly

For fastest MVP, build in this order:

1. **Create Xcode project** (5 min)
2. **Add existing ML model** (5 min) - already trained!
3. **Build CryptoService** (core encryption)
4. **Build basic Vault** (save/load encrypted files)
5. **Build PhotoService** (access camera roll)
6. **Build MLService** (run your trained model)
7. **Build minimal UI** (scan button → results → approve → vault)
8. **Add authentication last** (can test faster without it initially)

### Your Trained Model

Your model `PicSurge V1 1.mlmodel` is ready to use:
- Location: `PicSurge V1.mlproj/Models/PicSurge V1 1.mlmodel`
- Type: Image Classifier
- To integrate: Drag the `.mlmodel` file into Xcode project

### Testing Without Apple Developer Account

Without a paid developer account:
- Can run on simulator (but no real photos)
- Can run on your physical device for 7 days (free provisioning)
- Must re-install every 7 days
- Cannot use TestFlight or App Store

### Tips for Claude Code

When asking Claude Code to implement:
- Reference specific files from architecture doc
- Start with one service at a time
- Test each component before moving on
- Keep the PRD open for requirements reference

---

## 10. Success Criteria

### MVP Complete When:

- [ ] App launches and requires authentication
- [ ] Can set up PIN on first launch
- [ ] Face ID / Touch ID works for unlock
- [ ] Can scan photo library for surgical images
- [ ] Your trained model correctly identifies surgical photos
- [ ] Can review and select photos to secure
- [ ] Selected photos encrypted and saved to vault
- [ ] Original photos deleted from camera roll
- [ ] Vault displays secured photos
- [ ] Can view individual photos in vault
- [ ] App locks when backgrounded

### Stretch Goals:

- [ ] Background scanning works
- [ ] Settings fully implemented
- [ ] Polished UI with Dark Mode
- [ ] Comprehensive error handling
