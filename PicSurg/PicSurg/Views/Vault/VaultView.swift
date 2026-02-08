import SwiftUI

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
    @State private var showingShareSheet = false
    @State private var photosToShare: [UIImage] = []
    @State private var isPreparingShare = false
    @State private var isRestoring = false
    @State private var showingRestoreSuccess = false
    @State private var restoreSuccessCount = 0

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
            .toolbar {
                // Left side - selection count (Apple style) or title
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Text("\(selectedCount) Photo\(selectedCount == 1 ? "" : "s") Selected")
                            .font(.headline)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Vault")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            if !photos.isEmpty {
                                Text("\(photos.count) Item\(photos.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Right side - Select/Done button (Apple style uses Cancel in selection mode)
                ToolbarItem(placement: .navigationBarTrailing) {
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
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: photosToShare)
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
            .alert("Photos Restored", isPresented: $showingRestoreSuccess) {
                Button("OK") {}
            } message: {
                Text("\(restoreSuccessCount) photo\(restoreSuccessCount == 1 ? "" : "s") saved to your camera roll.")
            }
            .overlay {
                if isPreparingShare || isRestoring {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(isRestoring ? "Restoring photos..." : "Preparing photos...")
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

                // More options button
                Menu {
                    Button {
                        restoreSelectedPhotos()
                    } label: {
                        Label("Restore to Camera Roll", systemImage: "arrow.uturn.backward.circle")
                    }
                    .disabled(selectedCount == 0)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .foregroundColor(selectedCount > 0 ? .primary : .gray)
                .disabled(selectedCount == 0)
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
            var images: [UIImage] = []

            for id in selectedPhotoIds {
                do {
                    let data = try VaultService.shared.getPhoto(id: id)
                    if let image = UIImage(data: data) {
                        images.append(image)
                    }
                } catch {
                    print("Failed to load photo for sharing: \(error)")
                }
            }

            await MainActor.run {
                isPreparingShare = false

                if images.isEmpty {
                    Haptics.error()
                    errorMessage = "Could not prepare photos for sharing."
                    showingError = true
                } else {
                    // Log activity
                    appState.logActivity(.shared, count: images.count)

                    photosToShare = images
                    showingShareSheet = true
                }
            }
        }
    }

    private func restoreSelectedPhotos() {
        isRestoring = true

        Task {
            var successCount = 0

            for id in selectedPhotoIds {
                do {
                    let data = try VaultService.shared.getPhoto(id: id)
                    try await PhotoService.shared.saveToPhotoLibrary(data)
                    successCount += 1
                } catch {
                    print("Failed to restore photo: \(error)")
                }
            }

            await MainActor.run {
                isRestoring = false

                if successCount > 0 {
                    Haptics.success()
                    appState.logActivity(.restored, count: successCount)
                    restoreSuccessCount = successCount
                    showingRestoreSuccess = true
                    selectedPhotoIds.removeAll()
                    isSelectionMode = false
                } else {
                    Haptics.error()
                    errorMessage = "Could not restore photos. Please check your photo library permissions."
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

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
    @State private var showingShareSheet = false
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
                            showingShareSheet = true
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
        .sheet(isPresented: $showingShareSheet) {
            if let image = image {
                ShareSheet(items: [image])
            }
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

#Preview {
    VaultView()
}
