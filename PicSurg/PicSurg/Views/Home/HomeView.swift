import SwiftUI
import Photos

// MARK: - Logo View

/// App logo with subtle glow animation
struct LogoView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Glow effect behind logo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.gradientGlow.opacity(0.4),
                            Theme.Colors.gradientEnd.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(isPulsing ? 1.08 : 0.95)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            // App logo image
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .onAppear {
            isPulsing = true
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
    @State private var showingMenu = false

    private let batchSize = 100

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo and title
                        VStack(spacing: 12) {
                            LogoView()
                                .frame(height: 140)

                            Text("PicSurg")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.Colors.primary)
                        }
                        .padding(.top, 20)

                    Spacer()
                        .frame(height: 20)

                    // Scan button
                    scanButton
                        .padding(.horizontal, 40)

                    // Progress (if scanning)
                    if appState.isScanning {
                        scanProgressSection
                            .padding(.horizontal)
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

                // Menu button (three lines)
                menuButton
                    .padding(.top, 16)
                    .padding(.trailing, 20)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingReview) {
                ReviewView(results: $appState.scanResults, onComplete: {
                    showingReview = false
                    appState.scanResults = []
                })
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
        }
    }

    // MARK: - Sections

    private var menuButton: some View {
        Menu {
            Button {
                openPhotosApp()
            } label: {
                Label("Open Photos", systemImage: "photo.on.rectangle")
            }

            Button {
                appState.selectedTab = .settings
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Divider()

            Button {
                openAppSettings()
            } label: {
                Label("Photo Access Settings", systemImage: "lock.shield")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 44, height: 44)
                .background(Theme.Colors.cardBackground.opacity(0.8))
                .clipShape(Circle())
        }
    }

    private var scanButton: some View {
        Button(action: startScan) {
            HStack {
                if appState.isScanning {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text(appState.isScanning ? "Scanning..." : (appState.hasCompletedInitialScan ? "Scan New Photos" : "Scan Photos"))
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: appState.isScanning
                        ? [Color.gray, Color.gray]
                        : [Theme.Colors.gradientStart, Theme.Colors.gradientEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.Radius.medium)
            .scaleEffect(appState.isScanning ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.isScanning)
        }
        .disabled(appState.isScanning || !photoService.canAccessPhotos)
    }

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

    private func startScan() {
        Haptics.medium()
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
