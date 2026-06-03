//
//  MediaPickerSheet.swift
//  junto
//
//  Unified media picker: a grid of recent photos with a camera tile up front,
//  so you can pick from the library or shoot a new photo in one screen
//  (no camera/library chooser popup).
//

import SwiftUI
import Photos

struct MediaPickerSheet: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var assets: [PHAsset] = []
    @State private var status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @State private var showCamera = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        NavigationStack {
            Group {
                if status == .denied || status == .restricted {
                    deniedState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            cameraTile
                            ForEach(assets, id: \.localIdentifier) { asset in
                                PhotoGridTile(asset: asset) { image in
                                    selectedImage = image
                                    dismiss()
                                }
                            }
                        }
                        .padding(2)
                    }
                }
            }
            .background(Color.appSurface)
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .task { await requestAndLoad() }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(selectedImage: Binding(
                get: { nil },
                set: { img in
                    if let img {
                        selectedImage = img
                        showCamera = false
                        dismiss()
                    }
                }
            ))
            .ignoresSafeArea()
        }
    }

    private var cameraTile: some View {
        Button { showCamera = true } label: {
            Rectangle()
                .fill(Color.appSurfaceSecondary)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    VStack(spacing: Spacing.xs) {
                        Image("action.camera")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                        Text("Camera").font(.caption12)
                    }
                    .foregroundColor(.appSecondary)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var deniedState: some View {
        VStack(spacing: Spacing.md) {
            Text("Photo access is off")
                .font(.bodyLargeMedium)
                .foregroundColor(.appPrimary)
            Text("Enable photo access in Settings to choose a photo.")
                .font(.body14)
                .foregroundColor(.appSecondary)
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.bodyMedium)
            .foregroundColor(.appTint)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func requestAndLoad() async {
        let s = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run { status = s }
        guard s == .authorized || s == .limited else { return }

        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.fetchLimit = 90
        let result = PHAsset.fetchAssets(with: .image, options: opts)
        var fetched: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in fetched.append(asset) }
        await MainActor.run { assets = fetched }
    }
}

// MARK: - Photo tile

private struct PhotoGridTile: View {
    let asset: PHAsset
    let onSelect: (UIImage) -> Void

    @State private var thumb: UIImage?
    @State private var picked = false

    var body: some View {
        Button {
            loadFull()
        } label: {
            Rectangle()
                .fill(Color.appSurfaceSecondary)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let thumb {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .clipped()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task { loadThumb() }
    }

    private func loadThumb() {
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .opportunistic
        opts.resizeMode = .fast
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFill,
            options: opts
        ) { image, _ in
            if let image { thumb = image }
        }
    }

    private func loadFull() {
        guard !picked else { return }
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .highQualityFormat
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 1600, height: 1600),
            contentMode: .aspectFit,
            options: opts
        ) { image, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            guard let image, !isDegraded, !picked else { return }
            picked = true
            onSelect(image)
        }
    }
}
