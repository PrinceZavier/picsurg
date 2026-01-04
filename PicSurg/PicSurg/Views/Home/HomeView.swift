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

// MARK: - Stats Dashboard

struct StatsDashboardView: View {
    let photoCount: Int
    let storageUsed: String
    let lastScan: Date?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    icon: "lock.shield.fill",
                    value: "\(photoCount)",
                    label: "Secured"
                )

                StatCard(
                    icon: "internaldrive.fill",
                    value: storageUsed,
                    label: "Storage"
                )
            }

            // Only show last scan if provided (optional display)
            if let lastScan = lastScan {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Last scan: \(lastScan.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Radius.large)
        .shadow(Theme.Shadow.small)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.Colors.tertiaryBackground)
        .cornerRadius(Theme.Radius.medium)
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    let onOpenPhotos: () -> Void
    let onOpenVault: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "photo.on.rectangle",
                label: "Photos",
                color: .blue,
                action: onOpenPhotos
            )

            QuickActionButton(
                icon: "lock.shield",
                label: "Vault",
                color: Theme.Colors.primary,
                action: onOpenVault
            )
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(color)
            .background(color.opacity(0.12))
            .cornerRadius(Theme.Radius.medium)
        }
    }
}

// MARK: - Activity Feed

struct ActivityFeedView: View {
    let activities: [ActivityItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
            }

            if activities.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("No recent activity")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(activities.prefix(3)) { activity in
                    HStack(spacing: 12) {
                        Image(systemName: activity.icon)
                            .foregroundColor(activity.color)
                            .frame(width: 24)

                        Text(activity.message)
                            .font(.callout)

                        Spacer()

                        Text(activity.date.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Radius.large)
    }
}

// MARK: - Home View

/// Home screen with scan functionality
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var photoService = PhotoService.shared

    @State private var showingReview = false
    @State private var selectedScanLimit = 100
    @State private var showingNoResults = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isContinueScan = false

    private let scanLimitOptions = [50, 100, 250, 500, 1000]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo and title
                    VStack(spacing: 12) {
                        LogoView()
                            .frame(height: 140)

                        Text("PicSurg")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.top, 8)

                    // PROMINENT SCAN SECTION
                    VStack(spacing: 16) {
                        // Library coverage progress (if we've started scanning)
                        if appState.totalPhotosScanned > 0 && appState.totalLibraryPhotos > 0 {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Library Coverage")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(appState.scanCoveragePercent)%")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Theme.Colors.primary)
                                }

                                ProgressView(value: Double(appState.totalPhotosScanned), total: Double(appState.totalLibraryPhotos))
                                    .tint(Theme.Colors.primary)

                                Text("\(appState.totalPhotosScanned) of \(appState.totalLibraryPhotos) photos scanned")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Theme.Colors.tertiaryBackground)
                            .cornerRadius(Theme.Radius.medium)
                        }

                        // Last scan info
                        if let lastScan = appState.lastScanDate {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.success)
                                Text("Last scan: \(lastScan.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Scan options picker
                        if !appState.isScanning {
                            VStack(spacing: 8) {
                                // Toggle between scanning new photos and continuing
                                if appState.hasUnscannedPhotos && appState.totalPhotosScanned > 0 {
                                    Picker("Scan Mode", selection: $isContinueScan) {
                                        Text("Recent").tag(false)
                                        Text("Continue").tag(true)
                                    }
                                    .pickerStyle(.segmented)
                                    .onChange(of: isContinueScan) { _ in
                                        Haptics.selection()
                                    }
                                }

                                Text(isContinueScan ? "Continue scanning older photos:" : "Scan most recent photos:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Picker("Photos to scan", selection: $selectedScanLimit) {
                                    ForEach(scanLimitOptions, id: \.self) { limit in
                                        Text("\(limit)").tag(limit)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: selectedScanLimit) { _ in
                                    Haptics.selection()
                                }
                            }
                        }

                        // Scan button
                        scanButton

                        // Progress (if scanning)
                        if appState.isScanning {
                            scanProgressSection
                        }

                        // Permission warning
                        if !photoService.canAccessPhotos {
                            permissionWarningSection
                        }
                    }
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.Radius.large)
                    .shadow(Theme.Shadow.small)
                    .padding(.horizontal)

                    // Stats dashboard
                    StatsDashboardView(
                        photoCount: VaultService.shared.statistics.photoCount,
                        storageUsed: VaultService.shared.statistics.formattedSize,
                        lastScan: nil  // Already shown above
                    )
                    .padding(.horizontal)

                    // Quick actions
                    QuickActionsView(
                        onOpenPhotos: openPhotosApp,
                        onOpenVault: { appState.selectedTab = .vault }
                    )
                    .padding(.horizontal)

                    // Activity feed
                    ActivityFeedView(activities: appState.recentActivity)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingReview) {
                ReviewView(results: $appState.scanResults, onComplete: {
                    showingReview = false
                    appState.scanResults = []
                })
            }
            .alert("No Surgical Photos Found", isPresented: $showingNoResults) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No surgical photos were detected in the \(selectedScanLimit) most recent photos. Try scanning more photos or check that your surgical images are recent.")
            }
            .alert("Scan Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections

    private var scanButton: some View {
        Button(action: startScan) {
            HStack {
                if appState.isScanning {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isContinueScan ? "arrow.forward.circle" : "magnifyingglass")
                }
                Text(appState.isScanning ? "Scanning..." : (isContinueScan ? "Continue Scan" : "Scan Photos"))
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
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.3), value: appState.scanProgress)

            Text("\(Int(appState.scanProgress * 100))% complete")
                .foregroundColor(.secondary)
                .font(.callout)
                .contentTransition(.numericText())
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
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

    private func startScan() {
        Haptics.medium()
        Task {
            await performScan()
        }
    }

    private func performScan() async {
        appState.isScanning = true
        appState.scanProgress = 0

        // Get already-secured asset IDs to skip during scan
        let securedAssetIds = VaultService.shared.getSecuredAssetIds()

        // Fetch all photos and update library count
        let allAssets = photoService.fetchAllPhotos()
        await MainActor.run {
            appState.totalLibraryPhotos = allAssets.count
        }

        // Filter out secured assets
        let unsecuredAssets = allAssets.filter { !securedAssetIds.contains($0.localIdentifier) }

        // If continuing from previous scan, start after the oldest scanned date
        let assetsToScan: [PHAsset]
        if isContinueScan, let oldestDate = appState.oldestScannedPhotoDate {
            // Get photos older than our oldest scanned photo
            let olderAssets = unsecuredAssets.filter { asset in
                guard let creationDate = asset.creationDate else { return false }
                return creationDate < oldestDate
            }
            assetsToScan = Array(olderAssets.prefix(selectedScanLimit))
            print("📷 Continue scan: \(assetsToScan.count) photos older than \(oldestDate)")
        } else {
            // Scan most recent photos
            assetsToScan = Array(unsecuredAssets.prefix(selectedScanLimit))
        }

        let skippedCount = allAssets.count - unsecuredAssets.count
        if skippedCount > 0 {
            print("📷 Skipping \(skippedCount) already-secured photos")
        }
        print("📷 Scanning \(assetsToScan.count) of \(unsecuredAssets.count) unsecured photos")

        let assets = assetsToScan

        guard !assets.isEmpty else {
            await MainActor.run {
                appState.isScanning = false
                errorMessage = "No photos found in your library."
                showingError = true
            }
            return
        }

        // Load images and classify
        var imagesToClassify: [(identifier: String, image: UIImage)] = []

        for (index, asset) in assets.enumerated() {
            // Check for memory pressure - if getting low, process what we have
            if ProcessInfo.processInfo.physicalMemory > 0 {
                // On low memory devices, limit batch size
                let memoryLimit = ProcessInfo.processInfo.physicalMemory / 4
                let currentUsage = mach_task_self_
                var info = task_vm_info_data_t()
                var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size) / 4
                let result = withUnsafeMutablePointer(to: &info) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                        task_info(currentUsage, task_flavor_t(TASK_VM_INFO), $0, &count)
                    }
                }
                if result == KERN_SUCCESS && info.phys_footprint > memoryLimit {
                    print("⚠️ Memory pressure detected, processing \(imagesToClassify.count) images")
                    break
                }
            }

            if let image = await photoService.loadThumbnail(for: asset, size: CGSize(width: 300, height: 300)) {
                imagesToClassify.append((identifier: asset.localIdentifier, image: image))
            }

            // Update progress for loading phase (first 50%)
            await MainActor.run {
                appState.scanProgress = Float(index + 1) / Float(assets.count) * 0.5
            }
        }

        // Classify images
        let results = await MLService.shared.scanPhotos(images: imagesToClassify) { progress in
            Task { @MainActor in
                // Second 50% for classification
                appState.scanProgress = 0.5 + (progress * 0.5)
            }
        }

        // Track the oldest photo date for batch scanning progress
        let oldestPhotoDate = assets.compactMap { $0.creationDate }.min()

        await MainActor.run {
            appState.scanResults = results
            appState.isScanning = false
            appState.setLastScanDate(Date())

            // Update batch scanning progress
            if let oldestDate = oldestPhotoDate {
                appState.updateBatchScanProgress(oldestPhotoDate: oldestDate, photosScanned: assets.count)
            }

            // Log activity
            appState.logActivity(.scanned, count: assets.count)

            if !results.isEmpty {
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
