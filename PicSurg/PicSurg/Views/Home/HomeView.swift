import SwiftUI
import Photos
import PhotosUI

// MARK: - Scan Button Logo View (Shazam-style)

/// Interactive logo button that spins while scanning - like Shazam's "Tap to Shazam"
struct ScanButtonView: View {
    let isScanning: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPulsing = false
    @State private var rotation: Double = 0
    @State private var glowOpacity: Double = 0.4

    var body: some View {
        Button(action: {
            Haptics.medium()
            action()
        }) {
            VStack(spacing: 24) {
                ZStack {
                    // Outer pulsing glow rings (Shazam-style)
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                Theme.Colors.primary.opacity(isScanning ? 0.4 : 0.2),
                                lineWidth: 2
                            )
                            .frame(width: 280 + CGFloat(index * 50), height: 280 + CGFloat(index * 50))
                            .scaleEffect(isPulsing ? 1.15 : 0.9)
                            .opacity(isPulsing ? 0.0 : 0.7)
                            .animation(
                                .easeInOut(duration: 1.8)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                                value: isPulsing
                            )
                    }

                    // Main glow circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.gradientGlow.opacity(glowOpacity),
                                    Theme.Colors.gradientEnd.opacity(glowOpacity * 0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 80,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)
                        .scaleEffect(isScanning ? 1.2 : (isPulsing ? 1.08 : 0.95))
                        .animation(
                            isScanning
                                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                : .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            value: isPulsing
                        )

                    // Logo - scale up and clip to circle so colorful wheel fills the teal ring
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 340, height: 340) // Scale up to crop white corners
                        .clipShape(Circle()) // Clip to circle
                        .frame(width: 250, height: 250) // Display size (few pixels smaller than teal ring)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: isDisabled
                                            ? [Color.gray, Color.gray.opacity(0.5)]
                                            : [Theme.Colors.primary, Theme.Colors.gradientEnd],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 5
                                )
                        )
                        .shadow(color: Theme.Colors.primary.opacity(isScanning ? 0.6 : 0.3), radius: isScanning ? 30 : 15)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(isScanning ? 0.92 : 1.0)
                        .opacity(isDisabled ? 0.5 : 1.0)
                }
                .frame(width: 380, height: 380)

                // "Tap to PicSurg" text
                VStack(spacing: 8) {
                    if isScanning {
                        Text("Scanning...")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.primary)
                    } else {
                        Text("tap to")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("PicSurg")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isScanning)
            }
        }
        .disabled(isDisabled)
        .onAppear {
            isPulsing = true
        }
        .onChange(of: isScanning) { newValue in
            if newValue {
                // Start spinning when scanning begins
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.7
                }
            } else {
                // Stop spinning and reset when scanning ends
                withAnimation(.easeOut(duration: 0.5)) {
                    rotation = 0
                    glowOpacity = 0.4
                }
            }
        }
    }
}

// MARK: - Home View

/// Home screen with scan functionality
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var photoService = PhotoService.shared

    @State private var showingReview = false
    @State private var showingNoResults = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var currentBatchNumber = 0
    @State private var totalBatches = 0
    @State private var surgicalPhotosFound = 0

    // Photo picker state
    @State private var showingPhotoPicker = false
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var pendingPickerItems: [PhotosPickerItem] = []
    @State private var showingManualAddConfirm = false
    @State private var isAddingPhotos = false
    @State private var addedPhotosCount = 0
    @State private var showingAddSuccess = false

    private let batchSize = 100

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 20)

                    // Shazam-style scan button with spinning logo
                    ScanButtonView(
                        isScanning: appState.isScanning,
                        isDisabled: appState.isScanning || !photoService.canAccessPhotos
                    ) {
                        startScan()
                    }

                    // Progress (if scanning)
                    if appState.isScanning {
                        scanProgressSection
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // Last scan info (subtle, no background)
                    if !appState.isScanning, let lastScan = appState.lastScanActivity {
                        lastScanInfo(lastScan)
                    }

                    // Permission warning
                    if !photoService.canAccessPhotos {
                        permissionWarningSection
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Label("Add Photos Manually", systemImage: "plus.circle")
                        }

                        Button {
                            openPhotosApp()
                        } label: {
                            Label("Open Photos", systemImage: "photo.on.rectangle")
                        }

                        Button {
                            startScan()
                        } label: {
                            Label("Scan Photos", systemImage: "magnifyingglass")
                        }

                        Divider()

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                        }

                        Button {
                            openAppSettings()
                        } label: {
                            Label("Photo Access Settings", systemImage: "lock.shield")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showingReview) {
                ReviewView(results: $appState.scanResults, onComplete: {
                    showingReview = false
                    appState.scanResults = []
                })
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPickerItems, maxSelectionCount: 50, matching: .images)
            .onChange(of: selectedPickerItems) { newItems in
                if !newItems.isEmpty {
                    pendingPickerItems = newItems
                    selectedPickerItems = []
                    showingManualAddConfirm = true
                }
            }
            .alert("Scan Complete", isPresented: $showingNoResults) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No surgical photos were detected in your library.")
            }
            .alert("Scan Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Photos Added", isPresented: $showingAddSuccess) {
                Button("OK") {}
            } message: {
                Text("\(addedPhotosCount) photo\(addedPhotosCount == 1 ? "" : "s") secured in your vault.")
            }
            .alert("Secure \(pendingPickerItems.count) Photo\(pendingPickerItems.count == 1 ? "" : "s")?", isPresented: $showingManualAddConfirm) {
                Button("Cancel", role: .cancel) {
                    pendingPickerItems = []
                }
                Button("Secure & Remove") {
                    addPhotosManually(pendingPickerItems)
                }
            } message: {
                Text("This will encrypt and remove \(pendingPickerItems.count == 1 ? "this photo" : "these photos") from your camera roll. For full privacy, empty your Recently Deleted folder afterwards.")
            }
            .overlay {
                if isAddingPhotos {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Adding photos to vault...")
                                .font(.callout)
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var scanProgressSection: some View {
        VStack(spacing: 10) {
            ProgressView(value: Double(appState.scanProgress))
                .tint(Theme.Colors.primary)
                .animation(.easeInOut(duration: 0.3), value: appState.scanProgress)

            if totalBatches > 0 {
                Text("Batch \(currentBatchNumber) of \(totalBatches)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("\(Int(appState.scanProgress * 100))% complete")
                .foregroundColor(.secondary)
                .font(.callout)
                .contentTransition(.numericText())

            if surgicalPhotosFound > 0 {
                Text("\(surgicalPhotosFound) surgical photo\(surgicalPhotosFound == 1 ? "" : "s") found")
                    .font(.callout)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func lastScanInfo(_ activity: ActivityItem) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Last scan: \(activity.date.formatted(.relative(presentation: .named)))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var permissionWarningSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Photo access required")
                    .foregroundColor(.secondary)
            }
            .font(.callout)

            Button("Grant Access") {
                Task {
                    _ = await photoService.requestAuthorization()
                }
            }
            .font(.callout)
            .foregroundColor(Theme.Colors.primary)
        }
        .padding()
    }

    // MARK: - Actions

    private func openPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func addPhotosManually(_ items: [PhotosPickerItem]) {
        isAddingPhotos = true
        pendingPickerItems = []

        Task {
            var successCount = 0
            var assetIdentifiers: [String] = []

            for item in items {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        _ = try VaultService.shared.addPhoto(
                            imageData: data,
                            originalDate: Date()
                        )
                        successCount += 1
                        if let assetId = item.itemIdentifier {
                            assetIdentifiers.append(assetId)
                        }
                    }
                } catch {
                    print("Failed to add photo: \(error)")
                }
            }

            // Delete originals from camera roll
            if !assetIdentifiers.isEmpty {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
                if fetchResult.count > 0 {
                    do {
                        try await PHPhotoLibrary.shared().performChanges {
                            PHAssetChangeRequest.deleteAssets(fetchResult)
                        }
                    } catch {
                        print("Failed to delete from camera roll: \(error)")
                    }
                }
            }

            await MainActor.run {
                isAddingPhotos = false

                if successCount > 0 {
                    Haptics.success()
                    appState.logActivity(.secured, count: successCount)
                    addedPhotosCount = successCount
                    showingAddSuccess = true
                } else {
                    Haptics.error()
                    errorMessage = "Could not add photos to vault."
                    showingError = true
                }
            }
        }
    }

    private func startScan() {
        Task {
            await performScan()
        }
    }

    private func performScan() async {
        appState.isScanning = true
        appState.scanProgress = 0
        surgicalPhotosFound = 0
        currentBatchNumber = 0
        totalBatches = 0

        // Get already-secured asset IDs to skip during scan
        let securedAssetIds = VaultService.shared.getSecuredAssetIds()

        // Fetch all photos
        let allAssets = photoService.fetchAllPhotos()
        await MainActor.run {
            appState.totalLibraryPhotos = allAssets.count
        }

        // Filter out secured assets
        let unsecuredAssets = allAssets.filter { !securedAssetIds.contains($0.localIdentifier) }

        // Get only unscanned photos
        let allAssetIds = unsecuredAssets.map { $0.localIdentifier }
        let unscannedIds = Set(appState.getUnscannedPhotoIds(from: allAssetIds))

        // Filter to only unscanned assets
        let assetsToScan = unsecuredAssets.filter { unscannedIds.contains($0.localIdentifier) }

        print("📷 Total library: \(allAssets.count), Unsecured: \(unsecuredAssets.count), Unscanned: \(assetsToScan.count)")

        guard !assetsToScan.isEmpty else {
            await MainActor.run {
                appState.isScanning = false
                if appState.hasCompletedInitialScan {
                    errorMessage = "No new photos to scan."
                } else {
                    errorMessage = "No photos found in your library."
                }
                showingError = true
            }
            return
        }

        // Calculate batches
        let totalPhotos = assetsToScan.count
        totalBatches = (totalPhotos + batchSize - 1) / batchSize

        var allResults: [MLService.ScanResult] = []
        var scannedIds: [String] = []

        // Process in batches of 100
        for batchIndex in 0..<totalBatches {
            let startIndex = batchIndex * batchSize
            let endIndex = min(startIndex + batchSize, totalPhotos)
            let batchAssets = Array(assetsToScan[startIndex..<endIndex])

            await MainActor.run {
                currentBatchNumber = batchIndex + 1
            }

            print("📷 Processing batch \(batchIndex + 1)/\(totalBatches): \(batchAssets.count) photos")

            // Load images for this batch (max 100 at a time)
            var imagesToClassify: [(identifier: String, image: UIImage)] = []

            for (index, asset) in batchAssets.enumerated() {
                if let image = await photoService.loadThumbnail(for: asset, size: CGSize(width: 300, height: 300)) {
                    imagesToClassify.append((identifier: asset.localIdentifier, image: image))
                }
                scannedIds.append(asset.localIdentifier)

                // Update progress for loading phase (first 50% of this batch's portion)
                let batchProgress = Float(batchIndex) / Float(totalBatches)
                let withinBatchProgress = Float(index + 1) / Float(batchAssets.count) * 0.5
                let totalProgress = batchProgress + (withinBatchProgress / Float(totalBatches))

                await MainActor.run {
                    appState.scanProgress = totalProgress
                }
            }

            // Classify this batch
            let batchResults = await MLService.shared.scanPhotos(images: imagesToClassify) { progress in
                Task { @MainActor in
                    let batchProgress = Float(batchIndex) / Float(totalBatches)
                    let withinBatchProgress = 0.5 + (progress * 0.5)
                    let totalProgress = batchProgress + (withinBatchProgress / Float(totalBatches))
                    appState.scanProgress = totalProgress
                }
            }

            allResults.append(contentsOf: batchResults)

            await MainActor.run {
                surgicalPhotosFound = allResults.count
            }

            // Mark this batch as scanned
            await MainActor.run {
                appState.markPhotosAsScanned(ids: scannedIds)
                scannedIds = []
            }

            // Clear memory between batches
            imagesToClassify.removeAll()
        }

        // Mark initial scan as complete if this was the first full scan
        if !appState.hasCompletedInitialScan {
            await MainActor.run {
                appState.markInitialScanComplete()
            }
        }

        await MainActor.run {
            appState.scanResults = allResults
            appState.isScanning = false
            appState.scanProgress = 1.0
            appState.setLastScanDate(Date())

            // Log activity
            appState.logActivity(.scanned, count: totalPhotos)

            if !allResults.isEmpty {
                Haptics.success()
                showingReview = true
            } else {
                Haptics.warning()
                showingNoResults = true
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState.shared)
}
