import SwiftUI
import Photos

/// Review screen for approving/rejecting identified surgical photos
struct ReviewView: View {
    @Binding var results: [MLService.ScanResult]
    let onComplete: () -> Void

    @EnvironmentObject var appState: AppState
    @StateObject private var photoService = PhotoService.shared
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var unavailableAssets: Set<String> = []
    @State private var isProcessing = false
    @State private var processProgress: Float = 0
    @State private var showingConfirmation = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var showingUnavailableWarning = false
    @State private var errorMessage = ""
    @State private var securedCountForMessage = 0
    @State private var failedCount = 0
    @State private var removedCount = 0

    private var selectedCount: Int {
        results.filter { $0.isSelected }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header info
            HStack {
                Text("\(results.count) surgical photos found")
                    .font(.headline)
                Spacer()
                Text("\(selectedCount) selected")
                    .foregroundColor(.secondary)
            }
            .padding()

            // Photo grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(results.indices, id: \.self) { index in
                        PhotoThumbnailView(
                            image: thumbnails[results[index].assetIdentifier],
                            isSelected: results[index].isSelected,
                            confidence: results[index].confidence
                        )
                        .onTapGesture {
                            Haptics.light()
                            results[index].isSelected.toggle()
                        }
                    }
                }
            }

            // Action buttons
            VStack(spacing: 12) {
                if isProcessing {
                    ProgressView(value: Double(processProgress))
                    Text("Securing photos...")
                        .foregroundColor(.secondary)
                } else {
                    // Select all / Deselect all
                    HStack {
                        Button("Select All") {
                            for i in results.indices {
                                results[i].isSelected = true
                            }
                        }
                        .font(.callout)

                        Spacer()

                        Button("Deselect All") {
                            for i in results.indices {
                                results[i].isSelected = false
                            }
                        }
                        .font(.callout)
                    }

                    HStack(spacing: 15) {
                        Button(action: { onComplete() }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }

                        Button(action: { showingConfirmation = true }) {
                            Text("Secure \(selectedCount)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedCount > 0 ? Theme.Colors.primary : Color.gray)
                                .cornerRadius(Theme.Radius.medium)
                        }
                        .disabled(selectedCount == 0)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            validateAndLoadThumbnails()
        }
        .onChange(of: photoService.libraryChangeCount) { _ in
            // Photo library changed externally - revalidate assets
            revalidateAssets()
        }
        .alert("Photos Unavailable", isPresented: $showingUnavailableWarning) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(removedCount) photo\(removedCount == 1 ? " was" : "s were") deleted from your camera roll and removed from this list.")
        }
        .alert("Secure Photos", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Secure & Delete", role: .destructive) {
                secureSelectedPhotos()
            }
        } message: {
            Text("This will encrypt \(selectedCount) photos and remove them from your camera roll. This cannot be undone.")
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("Done") {
                onComplete()
            }
        } message: {
            Text("\(securedCountForMessage) photos have been secured in your vault.")
        }
        .alert("Partial Success", isPresented: $showingError) {
            Button("OK") {
                if securedCountForMessage > 0 {
                    onComplete()
                }
            }
        } message: {
            Text(errorMessage)
        }
    }

    private func validateAndLoadThumbnails() {
        Task {
            // First, validate which assets still exist
            let identifiers = results.map { $0.assetIdentifier }
            let existingIds = Set(photoService.filterExistingAssets(identifiers: identifiers))

            // Find unavailable assets
            let newUnavailable = Set(identifiers).subtracting(existingIds)

            await MainActor.run {
                unavailableAssets = newUnavailable

                // Remove unavailable results
                let countBefore = results.count
                results.removeAll { newUnavailable.contains($0.assetIdentifier) }
                let removed = countBefore - results.count

                if removed > 0 {
                    removedCount = removed
                    showingUnavailableWarning = true
                }
            }

            // Load thumbnails for remaining assets
            let assets = fetchAssets()
            for (identifier, asset) in assets {
                if let image = await photoService.loadThumbnail(for: asset) {
                    await MainActor.run {
                        thumbnails[identifier] = image
                    }
                }
            }
        }
    }

    private func revalidateAssets() {
        // Called when photo library changes externally
        Task {
            let identifiers = results.map { $0.assetIdentifier }
            let existingIds = Set(photoService.filterExistingAssets(identifiers: identifiers))

            let newUnavailable = Set(identifiers).subtracting(existingIds)

            if !newUnavailable.isEmpty {
                await MainActor.run {
                    unavailableAssets.formUnion(newUnavailable)

                    let countBefore = results.count
                    results.removeAll { newUnavailable.contains($0.assetIdentifier) }
                    let removed = countBefore - results.count

                    // Remove thumbnails for deleted assets
                    for id in newUnavailable {
                        thumbnails.removeValue(forKey: id)
                    }

                    if removed > 0 {
                        removedCount = removed
                        showingUnavailableWarning = true
                    }
                }
            }
        }
    }

    private func fetchAssets() -> [(String, PHAsset)] {
        let identifiers = results.map { $0.assetIdentifier }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

        var assets: [(String, PHAsset)] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append((asset.localIdentifier, asset))
        }
        return assets
    }

    private func secureSelectedPhotos() {
        isProcessing = true
        processProgress = 0
        failedCount = 0

        Task {
            let selectedResults = results.filter { $0.isSelected }
            let assets = fetchAssets()
            let assetsDict = Dictionary(uniqueKeysWithValues: assets)

            // Check available storage (rough estimate: 5MB per photo average)
            let estimatedSize = Int64(selectedResults.count * 5 * 1024 * 1024)
            if let freeSpace = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())[.systemFreeSize] as? Int64,
               freeSpace < estimatedSize {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Not enough storage space. Please free up at least \(ByteCountFormatter.string(fromByteCount: estimatedSize, countStyle: .file)) and try again."
                    showingError = true
                }
                return
            }

            var securedCount = 0
            var localFailedCount = 0
            var assetsToDelete: [PHAsset] = []
            var deleteWarning = false

            // Phase 1: Encrypt and save all photos to vault
            for (index, result) in selectedResults.enumerated() {
                guard let asset = assetsDict[result.assetIdentifier] else { continue }

                do {
                    // Load full resolution image
                    let imageData = try await photoService.loadFullResolutionImageData(for: asset)

                    // Add to vault (encrypted) with original asset ID for de-duplication
                    try VaultService.shared.addPhoto(
                        imageData: imageData,
                        originalDate: asset.creationDate ?? Date(),
                        originalAssetId: asset.localIdentifier
                    )

                    // Mark for deletion
                    assetsToDelete.append(asset)
                    securedCount += 1
                } catch {
                    localFailedCount += 1
                    print("Failed to secure photo: \(error)")
                }

                await MainActor.run {
                    // First 80% of progress is encryption
                    processProgress = Float(index + 1) / Float(selectedResults.count) * 0.8
                }
            }

            // Phase 2: Delete all photos from camera roll at once (single iOS confirmation)
            if !assetsToDelete.isEmpty {
                do {
                    try await photoService.deletePhotos(assetsToDelete)
                    print("✅ Deleted \(assetsToDelete.count) photos from camera roll")
                } catch {
                    deleteWarning = true
                    print("❌ Failed to delete photos from camera roll: \(error)")
                    // Photos are still secured in vault even if delete fails
                }
            }

            await MainActor.run {
                processProgress = 1.0
                isProcessing = false
                securedCountForMessage = securedCount
                failedCount = localFailedCount

                // Log activity
                if securedCount > 0 {
                    appState.logActivity(.secured, count: securedCount)
                }

                if localFailedCount > 0 || deleteWarning {
                    // Show error alert with details
                    Haptics.warning()
                    var message = ""
                    if localFailedCount > 0 {
                        message = "\(securedCount) photos secured. \(localFailedCount) photos could not be encrypted and remain in your camera roll."
                    }
                    if deleteWarning {
                        if !message.isEmpty { message += " " }
                        message += "Some photos could not be removed from your camera roll but are safely stored in your vault."
                    }
                    errorMessage = message
                    showingError = true
                } else if securedCount > 0 {
                    Haptics.success()
                    showingSuccess = true
                }
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let image: UIImage?
    let isSelected: Bool
    let confidence: Float

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fill)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .transition(.opacity)
                } else {
                    ProgressView()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: image != nil)

            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.black.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .scaleEffect(isSelected ? 1.0 : 0.9)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(6)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)

            // Confidence badge
            VStack {
                Spacer()
                HStack {
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    NavigationStack {
        ReviewView(results: .constant([]), onComplete: {})
    }
}
