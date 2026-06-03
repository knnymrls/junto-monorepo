//
//  ImagePickerButton.swift
//  mkrs-world
//
//  Image picker with photo library (PhotosPicker) and camera support
//

import SwiftUI
import PhotosUI
import UIKit

struct ImagePickerButton: View {
    @Binding var selectedImage: UIImage?
    var iconColor: Color = .appSecondary

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        Menu {
            Button(action: { showPhotoPicker = true }) {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }

            Button(action: { showCamera = true }) {
                Label("Take Photo", systemImage: "camera")
            }
        } label: {
            Image(systemName: "photo")
                .font(.heading3Regular)
                .foregroundColor(selectedImage != nil ? .appPrimary : iconColor)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Camera View (UIKit wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Multi Image Picker (for posts with multiple images)

struct MultiImagePickerButton: View {
    @Binding var selectedImages: [UIImage]
    var iconColor: Color = .appSecondary
    var maxImages: Int = 5

    @State private var showCamera = false
    @State private var showActionSheet = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        // PhotosPicker as the main button (direct tap opens photo library)
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: max(1, maxImages - selectedImages.count),
            matching: .images
        ) {
            Image(systemName: "photo")
                .font(.system(size: 18))
                .foregroundColor(!selectedImages.isEmpty ? .appPrimary : iconColor)
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            if selectedImages.count < maxImages {
                                selectedImages.append(image)
                            }
                        }
                    }
                }
                await MainActor.run {
                    selectedItems = []
                }
            }
        }
    }
}

// MARK: - Multi Image Picker with Camera Option

struct MultiImagePickerWithCameraButton: View {
    @Binding var selectedImages: [UIImage]
    var iconColor: Color = .appSecondary
    var maxImages: Int = 5

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        Menu {
            Button(action: { showPhotoPicker = true }) {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }

            Button(action: { showCamera = true }) {
                Label("Take Photo", systemImage: "camera")
            }
        } label: {
            Image("action.image")
                .renderingMode(.template)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(!selectedImages.isEmpty ? .appPrimary : iconColor)
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItems,
            maxSelectionCount: max(1, maxImages - selectedImages.count),
            matching: .images
        )
        .onChange(of: selectedItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            if selectedImages.count < maxImages {
                                selectedImages.append(image)
                            }
                        }
                    }
                }
                await MainActor.run {
                    selectedItems = []
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            MultiCameraView(selectedImages: $selectedImages)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Multi Camera View (appends to array)

struct MultiCameraView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MultiCameraView

        init(_ parent: MultiCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Compact variant for comment composer

struct CompactImagePickerButton: View {
    @Binding var selectedImage: UIImage?
    var iconName: String = "action.image"
    var iconColor: Color = .appSecondary

    @State private var showPicker = false

    var body: some View {
        // Tapping opens the unified media picker (photo grid + camera tile).
        Button(action: { showPicker = true }) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(selectedImage != nil ? .appPrimary : iconColor)
                .frame(width: 28, height: 28)
        }
        .sheet(isPresented: $showPicker) {
            MediaPickerSheet(selectedImage: $selectedImage)
                .presentationDetents([.large])
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ImagePickerButton(selectedImage: .constant(nil))
        CompactImagePickerButton(selectedImage: .constant(nil))
    }
    .padding()
}
