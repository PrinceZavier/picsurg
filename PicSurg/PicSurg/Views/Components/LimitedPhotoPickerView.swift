import SwiftUI
import Photos
import PhotosUI

/// Custom photo picker that respects Limited Photo Library access.
/// Unlike the system PhotosPicker (PHPickerViewController), this only shows
/// photos the user has explicitly granted access to.
struct LimitedPhotoPickerView: View {
    let maxSelection: Int
    let onSelect: ([PHAsset]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var assets: [PHAsset] = []
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var selectedIds: Set<String> = []
    @State private var isLoading = true

    private let imageManager = PHCachingImageManager()
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView("Loading photos...")
                    Spacer()
                } else if assets.isEmpty {
                    emptyState
                } else {
                    photoGrid
                }

                if !assets.isEmpty && !isLoading {
                    bottomBar
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if PhotoService.shared.hasLimitedAccess {
                        Button("Manage Access") {
                            presentLimitedLibraryPicker()
                        }
                        .font(.callout)
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
        .onAppear { loadAuthorizedPhotos() }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Photos Available")
                .font(.title2)
                .fontWeight(.semibold)

            if PhotoService.shared.hasLimitedAccess {
                Text("You've given PicSurg limited photo access. Tap \"Manage Access\" to select which photos PicSurg can see.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                Button {
                    presentLimitedLibraryPicker()
                } label: {
                    Text("Manage Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.primary)
                        .cornerRadius(Theme.Radius.medium)
                }
            } else {
                Text("No photos found in your library.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
    }

    private var photoGrid: some View {
        VStack(spacing: 0) {
            if PhotoService.shared.hasLimitedAccess {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Showing only photos you've granted access to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Theme.Colors.primary.opacity(0.08))
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(assets, id: \.localIdentifier) { asset in
                        PickerThumbnailView(
                            image: thumbnails[asset.localIdentifier],
                            isSelected: selectedIds.contains(asset.localIdentifier)
                        )
                        .onTapGesture {
                            toggleSelection(asset)
                        }
                        .onAppear {
                            loadThumbnail(for: asset)
                        }
                    }
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Text("\(selectedIds.count) selected")
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    let selected = assets.filter { selectedIds.contains($0.localIdentifier) }
                    onSelect(selected)
                    dismiss()
                } label: {
                    Text("Add \(selectedIds.count) Photo\(selectedIds.count == 1 ? "" : "s")")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(selectedIds.isEmpty ? Color.gray : Theme.Colors.primary)
                        .cornerRadius(Theme.Radius.medium)
                }
                .disabled(selectedIds.isEmpty)
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Actions

    private func toggleSelection(_ asset: PHAsset) {
        Haptics.light()
        let id = asset.localIdentifier
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else if selectedIds.count < maxSelection {
            selectedIds.insert(id)
        }
    }

    private func loadAuthorizedPhotos() {
        Task {
            let fetchedAssets = PhotoService.shared.fetchAllPhotos()
            await MainActor.run {
                assets = fetchedAssets
                isLoading = false
            }
        }
    }

    private func loadThumbnail(for asset: PHAsset) {
        let id = asset.localIdentifier
        guard thumbnails[id] == nil else { return }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if !isDegraded, let image = image {
                DispatchQueue.main.async {
                    thumbnails[id] = image
                }
            }
        }
    }

    private func presentLimitedLibraryPicker() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: topVC) { _ in
            DispatchQueue.main.async {
                self.loadAuthorizedPhotos()
            }
        }
    }
}

// MARK: - Picker Thumbnail

private struct PickerThumbnailView: View {
    let image: UIImage?
    let isSelected: Bool

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
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
