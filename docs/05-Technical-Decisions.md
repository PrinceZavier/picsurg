# PicSurg - Technical Decisions & Solutions

**Version:** 1.0
**Last Updated:** January 2026

This document explains the technical decisions made during development and how specific problems were solved. It serves as a reference for understanding why certain approaches were chosen.

---

## Table of Contents

1. [ML Model Integration](#1-ml-model-integration)
2. [Photo Library Handling](#2-photo-library-handling)
3. [Error Handling Strategy](#3-error-handling-strategy)
4. [Edge Cases & Solutions](#4-edge-cases--solutions)
5. [Security Decisions](#5-security-decisions)
6. [Performance Optimizations](#6-performance-optimizations)

---

## 1. ML Model Integration

### Problem: ML Inference Crashes on Device

**Symptom**: App crashed with "Could not create inference context" error when running ML classification on real iPhone.

**Root Cause**: The Neural Engine or GPU compute units were not compatible with certain device configurations.

**Solution**: Force CPU-only computation in MLService.swift:

```swift
private func loadModel() {
    let config = MLModelConfiguration()
    config.computeUnits = .cpuOnly  // Key fix

    let mlModel = try PicSurgeV1(configuration: config).model
    model = try VNCoreMLModel(for: mlModel)
}
```

**Trade-off**: Slightly slower classification, but works reliably across all devices.

**File**: [MLService.swift](../PicSurg/PicSurg/Services/MLService.swift) lines 36-51

---

### Problem: "Continuation Resumed More Than Once" Error

**Symptom**: Crash during batch classification with Swift concurrency error.

**Root Cause**: Using `withCheckedThrowingContinuation` with callback-based Vision API that could call the completion handler multiple times.

**Solution**: Use `Task.detached` instead of continuation:

```swift
private func classifyImageSync(_ cgImage: CGImage) async throws -> ClassificationResult {
    return try await Task.detached(priority: .userInitiated) {
        let request = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        // Process results...
    }.value
}
```

**File**: [MLService.swift](../PicSurg/PicSurg/Services/MLService.swift) lines 72-106

---

### Problem: ML Doesn't Work in Simulator

**Symptom**: Classification always fails when running in iOS Simulator.

**Root Cause**: CoreML models may not run correctly in simulator environment.

**Solution**: Detect simulator and provide mock results for UI testing:

```swift
#if targetEnvironment(simulator)
private let isSimulator = true
#else
private let isSimulator = false
#endif

// In scanPhotos():
#if targetEnvironment(simulator)
if failCount > 3 && successCount == 0 {
    // Add mock surgical result for UI testing
    let mockResult = ScanResult(...)
    results.append(mockResult)
}
#endif
```

**File**: [MLService.swift](../PicSurg/PicSurg/Services/MLService.swift) lines 25-30, 167-181

---

## 2. Photo Library Handling

### Problem: App Crashes with Large Photo Libraries

**Symptom**: App crashed or became unresponsive when user had 8,000+ photos and selected "Allow All Photos".

**Root Cause**: Trying to load and classify too many photos at once exceeded memory limits.

**Solution**: Add scan limit picker to let users control batch size:

```swift
private let scanLimitOptions = [50, 100, 250, 500, 1000]
@State private var selectedScanLimit = 100

// In performScan():
let allAssets = photoService.fetchAllPhotos()
let assets = Array(allAssets.prefix(selectedScanLimit))
```

**User Experience**: Segmented control on Home screen lets user choose 50, 100, 250, 500, or 1000 photos.

**File**: [HomeView.swift](../PicSurg/PicSurg/Views/Home/HomeView.swift) lines 13, 16, 54-62

---

### Problem: Multiple Delete Confirmations

**Symptom**: When securing photos, iOS showed a delete confirmation dialog for each photo individually.

**Root Cause**: Calling `deletePhoto()` separately for each asset.

**Solution**: Collect all assets, then delete in single batch:

```swift
var assetsToDelete: [PHAsset] = []

// Phase 1: Encrypt all photos
for result in selectedResults {
    // ... encrypt and save ...
    assetsToDelete.append(asset)
}

// Phase 2: Single bulk delete
if !assetsToDelete.isEmpty {
    try await photoService.deletePhotos(assetsToDelete)
}
```

**User Experience**: Single iOS confirmation: "Allow PicSurg to delete X photos?"

**File**: [ReviewView.swift](../PicSurg/PicSurg/Views/Review/ReviewView.swift) lines 190-200

---

### Problem: Photo Access Settings Not Changeable

**Symptom**: User wanted to change photo access permissions after initial setup.

**Root Cause**: iOS only shows the permission dialog once; subsequent changes must be done in Settings.

**Solution**: Add Photo Access section in Settings with direct link:

```swift
private var photoAccessStatus: String {
    switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
    case .authorized: return "Full Access"
    case .limited: return "Limited Access"
    case .denied: return "Denied"
    // ...
    }
}

private func openAppSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

**File**: [SettingsView.swift](../PicSurg/PicSurg/Views/Settings/SettingsView.swift) lines 18-37

---

## 3. Error Handling Strategy

### Approach: Local Error State with Alerts

**Decision**: Each view manages its own error state rather than using a global error handler.

**Rationale**:
- Errors are contextual to the current operation
- Alerts appear immediately where the user is
- No complex state management needed

**Implementation Pattern**:

```swift
struct SomeView: View {
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        // ... content ...
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func someOperation() {
        do {
            try riskyOperation()
        } catch {
            errorMessage = "User-friendly message here"
            showingError = true
        }
    }
}
```

### AppError Struct

For common errors, we defined reusable error types:

```swift
struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isRecoverable: Bool

    static func photoAccessDenied() -> AppError { ... }
    static func encryptionFailed() -> AppError { ... }
    static func storageFull() -> AppError { ... }
    // etc.
}
```

**File**: [AppState.swift](../PicSurg/PicSurg/Models/AppState.swift) lines 5-66

---

## 4. Edge Cases & Solutions

### Zero Surgical Photos Found

**Problem**: User scans photos but ML finds nothing surgical.

**Solution**: Show helpful alert with suggestions:

```swift
.alert("No Surgical Photos Found", isPresented: $showingNoResults) {
    Button("OK", role: .cancel) {}
} message: {
    Text("No surgical photos were detected in the \(selectedScanLimit) most recent photos. Try scanning more photos or check that your surgical images are recent.")
}
```

**File**: [HomeView.swift](../PicSurg/PicSurg/Views/Home/HomeView.swift) lines 130-134

---

### Empty Vault State

**Problem**: New users see empty vault and don't know what to do.

**Solution**: Step-by-step instructions instead of just "No photos":

```swift
private var emptyState: some View {
    VStack(spacing: 20) {
        Image(systemName: "lock.shield")
        Text("No Secured Photos")
        Text("Your encrypted photos will appear here once you secure them.")

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "1.circle.fill")
                Text("Go to Home tab")
            }
            HStack {
                Image(systemName: "2.circle.fill")
                Text("Tap \"Scan Photos\"")
            }
            HStack {
                Image(systemName: "3.circle.fill")
                Text("Review and secure detected photos")
            }
        }
    }
}
```

**File**: [VaultView.swift](../PicSurg/PicSurg/Views/Vault/VaultView.swift) lines 55-96

---

### Low Storage Space

**Problem**: App could fail mid-way through securing photos if storage runs out.

**Solution**: Pre-check available storage before starting:

```swift
// Estimate ~5MB per photo average
let estimatedSize = Int64(selectedResults.count * 5 * 1024 * 1024)
if let freeSpace = try? FileManager.default.attributesOfFileSystem(
    forPath: NSHomeDirectory())[.systemFreeSize] as? Int64,
   freeSpace < estimatedSize {
    errorMessage = "Not enough storage space. Please free up at least \(ByteCountFormatter.string(fromByteCount: estimatedSize, countStyle: .file)) and try again."
    showingError = true
    return
}
```

**File**: [ReviewView.swift](../PicSurg/PicSurg/Views/Review/ReviewView.swift) lines 174-184

---

### Memory Pressure During Scan

**Problem**: Loading many photo thumbnails could exhaust memory on older devices.

**Solution**: Monitor memory usage and stop gracefully if needed:

```swift
for (index, asset) in assets.enumerated() {
    // Check memory pressure
    let memoryLimit = ProcessInfo.processInfo.physicalMemory / 4  // 25%
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4

    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }

    if result == KERN_SUCCESS && info.phys_footprint > memoryLimit {
        print("⚠️ Memory pressure detected, processing what we have")
        break
    }

    // Continue loading...
}
```

**Trade-off**: May not scan all requested photos, but prevents crashes.

**File**: [HomeView.swift](../PicSurg/PicSurg/Views/Home/HomeView.swift) lines 174-191

---

### Partial Secure Failure

**Problem**: Some photos might fail to encrypt while others succeed.

**Solution**: Track failures, show detailed message, continue with successful ones:

```swift
var securedCount = 0
var localFailedCount = 0

for result in selectedResults {
    do {
        // Encrypt and save
        securedCount += 1
    } catch {
        localFailedCount += 1
    }
}

// Show appropriate message
if localFailedCount > 0 {
    errorMessage = "\(securedCount) photos secured. \(localFailedCount) photos could not be encrypted and remain in your camera roll."
    showingError = true
} else {
    showingSuccess = true
}
```

**Key Principle**: Only delete photos that were successfully saved to vault.

**File**: [ReviewView.swift](../PicSurg/PicSurg/Views/Review/ReviewView.swift) lines 209-226

---

## 5. Security Decisions

### Encryption Algorithm: AES-256-GCM

**Choice**: AES-256-GCM via Apple's CryptoKit

**Rationale**:
- Industry standard for data at rest
- GCM provides authentication (detects tampering)
- Native Apple implementation (hardware accelerated)
- HIPAA compliant

### Key Storage: iOS Keychain

**Choice**: Store encryption key in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

**Rationale**:
- Hardware-backed security on devices with Secure Enclave
- Key never leaves device
- Protected by device passcode

### PIN Storage: Hashed Only

**Choice**: Store SHA-256 hash of PIN, not the PIN itself

**Rationale**:
- PIN cannot be recovered even if Keychain is compromised
- Standard security practice

**Note**: For production, consider using proper KDF like PBKDF2 or Argon2 (documented in Issue #1)

### Vault Exclusion from Backups

**Choice**: Set `isExcludedFromBackup = true` on vault directory

**Rationale**:
- Encrypted photos stay only on device
- No risk of backup exposure
- iCloud/iTunes backups won't include vault

---

## 6. Performance Optimizations

### Thumbnail Caching

**Implementation**: PHCachingImageManager for efficient thumbnail loading

```swift
private let imageManager = PHCachingImageManager()

func loadThumbnail(for asset: PHAsset, size: CGSize) async -> UIImage? {
    await withCheckedContinuation { continuation in
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            // Only return final image, not degraded preview
            if !(info?[PHImageResultIsDegradedKey] as? Bool ?? false) {
                continuation.resume(returning: image)
            }
        }
    }
}
```

### Lazy Loading in Vault

**Implementation**: LazyVGrid with on-demand thumbnail loading

```swift
LazyVGrid(columns: columns, spacing: 2) {
    ForEach(photos) { photo in
        VaultThumbnailView(image: thumbnails[photo.id])
            .onAppear {
                loadThumbnail(for: photo)  // Load when scrolled into view
            }
    }
}
```

### Background Classification

**Implementation**: All ML work runs on background thread via Task.detached

```swift
return try await Task.detached(priority: .userInitiated) {
    // CPU-intensive ML work here
}.value
```

This keeps the UI responsive during scanning.

---

## Summary

These technical decisions were made to balance:
- **Reliability**: App should never crash
- **User Experience**: Clear feedback, no confusion
- **Security**: HIPAA-appropriate data protection
- **Performance**: Responsive UI even with large libraries

For questions about specific implementations, refer to the source files linked throughout this document.
