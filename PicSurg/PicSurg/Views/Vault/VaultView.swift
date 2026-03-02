import SwiftUI
import Photos
import PhotosUI

/// Vault view showing secured photos with multi-select support
struct VaultView: View {
    @EnvironmentObject var appState: AppState
    @State private var photos: [VaultPhoto] = []
    @State private var thumbnails: [UUID: UIImage] = [:]
    @State private var selectedPhoto: VaultPhoto?
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""

    // Multi-select state
    @State private var isSelectionMode = false
    @State private var selectedPhotoIds: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    @State private var isPreparingShare = false
    @State private var showingPhotoPicker = false
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var isAddingPhotos = false
    @State private var addedPhotosCount = 0
    @State private var showingAddSuccess = false
    @State private var pendingPickerItems: [PhotosPickerItem] = []
    @State private var showingManualAddConfirm = false

    private var selectedCount: Int {
        selectedPhotoIds.count
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if isLoading {
                        Spacer()
                        ProgressView("Loading vault...")
                        Spacer()
                    } else if photos.isEmpty {
                        emptyState
                    } else {
                        photoGrid
                    }
                }

                // Action bar when in selection mode
                if isSelectionMode && !photos.isEmpty {
                    selectionActionBar
                }
            }
            .navigationTitle(isSelectionMode ? "\(selectedCount) Photo\(selectedCount == 1 ? "" : "s") Selected" : "Vault")
            .toolbar {
                // Right side - Menu button and Select/Cancel
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !isSelectionMode {
                        // Hamburger menu
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
                                appState.selectedTab = .home
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

                    if !photos.isEmpty && !isLoading {
                        Button(isSelectionMode ? "Cancel" : "Select") {
                            Haptics.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedPhotoIds.removeAll()
                                }
                            }
                        }
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadPhotos()
            }
            .sheet(item: $selectedPhoto) { photo in
                SecurePhotoView(photo: photo, onDelete: {
                    deletePhoto(photo)
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Delete \(selectedCount) Photo\(selectedCount == 1 ? "" : "s")?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteSelectedPhotos()
                }
            } message: {
                Text("This will permanently delete the selected photo\(selectedCount == 1 ? "" : "s") from your vault. This cannot be undone.")
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
                if isPreparingShare || isAddingPhotos {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(isAddingPhotos ? "Adding photos to vault..." : "Preparing photos...")
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

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary.opacity(0.5))

            Text("No Secured Photos")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your encrypted photos will appear here once you secure them.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Go to Home tab")
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 12) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Tap \"Scan Photos\"")
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 12) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Review and secure detected photos")
                        .foregroundColor(.secondary)
                }
            }
            .font(.callout)
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.Radius.medium)

            Spacer()
        }
        .padding()
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(photos) { photo in
                    VaultThumbnailView(
                        image: thumbnails[photo.id],
                        isSelected: selectedPhotoIds.contains(photo.id),
                        isSelectionMode: isSelectionMode
                    )
                    .onTapGesture {
                        handlePhotoTap(photo)
                    }
                    .onAppear {
                        loadThumbnail(for: photo)
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: photos.count)
        }
    }

    private var selectionActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                // Share button (left)
                Button {
                    shareSelectedPhotos()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .disabled(selectedCount == 0)
                .foregroundColor(selectedCount > 0 ? .primary : .gray)

                Spacer()

                // Select All / Deselect All (center)
                if selectedPhotoIds.count == photos.count {
                    Button("Deselect All") {
                        Haptics.light()
                        selectedPhotoIds.removeAll()
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                } else {
                    Button("Select All") {
                        Haptics.light()
                        selectedPhotoIds = Set(photos.map { $0.id })
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                }

                Spacer()

                // Delete button (right)
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .disabled(selectedCount == 0)
                .foregroundColor(selectedCount > 0 ? .primary : .gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func handlePhotoTap(_ photo: VaultPhoto) {
        if isSelectionMode {
            Haptics.light()
            toggleSelection(photo.id)
        } else {
            Haptics.light()
            selectedPhoto = photo
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedPhotoIds.contains(id) {
            selectedPhotoIds.remove(id)
        } else {
            selectedPhotoIds.insert(id)
        }
    }

    private func loadPhotos() {
        isLoading = true
        Task {
            do {
                let loadedPhotos = try VaultService.shared.listPhotos()
                await MainActor.run {
                    photos = loadedPhotos.sorted { $0.addedDate > $1.addedDate }
                    isLoading = false

                    // Preload first batch of thumbnails for smooth scrolling
                    let preloadIds = photos.prefix(20).map { $0.id }
                    VaultService.shared.preloadThumbnails(for: Array(preloadIds))
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Could not load your secured photos. Please try again."
                    showingError = true
                }
            }
        }
    }

    private func loadThumbnail(for photo: VaultPhoto) {
        guard thumbnails[photo.id] == nil else { return }

        Task {
            do {
                // Use cached thumbnail for better performance
                let image = try VaultService.shared.getCachedThumbnail(id: photo.id)
                await MainActor.run {
                    thumbnails[photo.id] = image
                }
            } catch {
                print("Failed to load thumbnail: \(error)")
            }
        }
    }

    private func deletePhoto(_ photo: VaultPhoto) {
        do {
            try VaultService.shared.deletePhoto(id: photo.id)
            Haptics.success()
            photos.removeAll { $0.id == photo.id }
            thumbnails.removeValue(forKey: photo.id)
            selectedPhoto = nil

            // Log activity
            appState.logActivity(.deleted, count: 1)
        } catch {
            Haptics.error()
            errorMessage = "Could not delete the photo. Please try again."
            showingError = true
        }
    }

    private func deleteSelectedPhotos() {
        var failedCount = 0

        for id in selectedPhotoIds {
            do {
                try VaultService.shared.deletePhoto(id: id)
            } catch {
                failedCount += 1
                print("Failed to delete photo \(id): \(error)")
            }
        }

        // Update UI
        photos.removeAll { selectedPhotoIds.contains($0.id) }
        for id in selectedPhotoIds {
            thumbnails.removeValue(forKey: id)
        }

        let deletedCount = selectedPhotoIds.count - failedCount
        selectedPhotoIds.removeAll()

        // Log activity
        if deletedCount > 0 {
            appState.logActivity(.deleted, count: deletedCount)
        }

        withAnimation {
            isSelectionMode = false
        }

        if failedCount > 0 {
            Haptics.warning()
            errorMessage = "Deleted \(deletedCount) photos. \(failedCount) could not be deleted."
            showingError = true
        } else {
            Haptics.success()
        }
    }

    private func shareSelectedPhotos() {
        isPreparingShare = true

        Task {
            var urls: [URL] = []
            let tempDir = FileManager.default.temporaryDirectory

            for (index, id) in selectedPhotoIds.enumerated() {
                do {
                    let data = try VaultService.shared.getPhoto(id: id)
                    let fileURL = tempDir.appendingPathComponent("vault_photo_\(index).jpg")
                    try data.write(to: fileURL)
                    urls.append(fileURL)
                } catch {
                    print("Failed to load photo for sharing: \(error)")
                }
            }

            await MainActor.run {
                isPreparingShare = false

                if urls.isEmpty {
                    Haptics.error()
                    errorMessage = "Could not prepare photos for sharing."
                    showingError = true
                } else {
                    appState.logActivity(.shared, count: urls.count)
                    presentShareSheet(items: urls) {
                        // Clean up temp files after share completes
                        for url in urls {
                            try? FileManager.default.removeItem(at: url)
                        }
                    }
                }
            }
        }
    }

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
                    loadPhotos()
                } else {
                    Haptics.error()
                    errorMessage = "Could not add photos to vault."
                    showingError = true
                }
            }
        }
    }
}

// MARK: - VaultThumbnailView

struct VaultThumbnailView: View {
    let image: UIImage?
    var isSelected: Bool = false
    var isSelectionMode: Bool = false

    var body: some View {
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

            // Selection indicator
            if isSelectionMode {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.blue : Color.black.opacity(0.4))
                                .frame(width: 26, height: 26)
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
                    }
                    Spacer()
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected && isSelectionMode ? Color.blue : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected && isSelectionMode ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.25), value: image != nil)
    }
}

// MARK: - SecurePhotoView

struct SecurePhotoView: View {
    let photo: VaultPhoto
    let onDelete: () -> Void
    var onRestore: (() -> Void)? = nil

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var showingDeleteConfirmation = false
    @State private var showingRestoreConfirmation = false
    @State private var showingRestoreSuccess = false
    @State private var showingRestoreError = false
    @State private var isRestoring = false
    @State private var scale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        scale = max(1.0, min(scale, 3.0))
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = scale > 1 ? 1 : 2
                            }
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            sharePhoto()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            showingRestoreConfirmation = true
                        } label: {
                            Label("Restore to Camera Roll", systemImage: "arrow.uturn.backward.circle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                    .disabled(isRestoring)
                }

                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(photo.originalDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            loadFullImage()
        }
        .alert("Delete Photo", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will permanently delete this photo from your vault. This cannot be undone.")
        }
        .alert("Restore to Camera Roll", isPresented: $showingRestoreConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Restore") {
                restoreToPhotoLibrary()
            }
        } message: {
            Text("This will save the photo back to your camera roll. The photo will remain in your vault.")
        }
        .alert("Photo Restored", isPresented: $showingRestoreSuccess) {
            Button("OK") {}
        } message: {
            Text("The photo has been saved to your camera roll.")
        }
        .alert("Restore Failed", isPresented: $showingRestoreError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Could not restore the photo. Please check your photo library permissions.")
        }
        .overlay {
            if isRestoring {
                ZStack {
                    Color.black.opacity(0.5)
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                        Text("Restoring...")
                            .foregroundColor(.white)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }

    private func sharePhoto() {
        guard let image = image,
              let data = image.jpegData(compressionQuality: 0.9) else { return }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("vault_photo_share.jpg")
        do {
            try data.write(to: fileURL)
            presentShareSheet(items: [fileURL]) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to write temp file for sharing: \(error)")
        }
    }

    private func restoreToPhotoLibrary() {
        isRestoring = true

        Task {
            do {
                let data = try VaultService.shared.getPhoto(id: photo.id)
                try await PhotoService.shared.saveToPhotoLibrary(data)

                await MainActor.run {
                    isRestoring = false
                    Haptics.success()
                    showingRestoreSuccess = true
                    appState.logActivity(.restored, count: 1)
                    onRestore?()
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    Haptics.error()
                    showingRestoreError = true
                }
                print("Failed to restore photo: \(error)")
            }
        }
    }

    private func loadFullImage() {
        Task {
            do {
                let data = try VaultService.shared.getPhoto(id: photo.id)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        image = loadedImage
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Share Helper

/// Presents UIActivityViewController via UIKit for full share sheet (AirDrop, Messages, Mail, etc.)
func presentShareSheet(items: [Any], completion: (() -> Void)? = nil) {
    let activityVC = UIActivityViewController(
        activityItems: items,
        applicationActivities: nil
    )
    activityVC.completionWithItemsHandler = { _, _, _, _ in
        completion?()
    }

    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootVC = windowScene.windows.first?.rootViewController else { return }

    var topVC = rootVC
    while let presented = topVC.presentedViewController {
        topVC = presented
    }
    activityVC.popoverPresentationController?.sourceView = topVC.view
    topVC.present(activityVC, animated: true)
}

#Preview {
    VaultView()
}
