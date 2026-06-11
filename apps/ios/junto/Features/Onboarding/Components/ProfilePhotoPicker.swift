//
//  ProfilePhotoPicker.swift
//  junto
//
//  Circular avatar with camera icon overlay — triggers image picker with native crop
//

import SwiftUI

struct ProfilePhotoPicker: View {
    @Binding var image: UIImage?
    /// Existing remote avatar shown until a new photo is picked (Edit Profile).
    var existingAvatarUrl: String? = nil
    var existingName: String = "?"
    var size: CGFloat = 100
    @State private var showPicker = false

    var body: some View {
        Button { showPicker = true } label: {
            ZStack(alignment: .bottomTrailing) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else if existingAvatarUrl != nil {
                    AvatarView(
                        avatarUrl: existingAvatarUrl,
                        name: existingName,
                        size: size
                    )
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.appSecondary, Color.appInputFill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                }

                // Camera icon
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.appOnAccent)
                    )
                    .offset(x: -2, y: -2)
            }
        }
        .sheet(isPresented: $showPicker) {
            ImageCropPicker(image: $image)
                .ignoresSafeArea()
        }
    }
}

// MARK: - UIImagePickerController wrapper with allowsEditing

private struct ImageCropPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImageCropPicker

        init(_ parent: ImageCropPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let edited = info[.editedImage] as? UIImage {
                parent.image = edited
            } else if let original = info[.originalImage] as? UIImage {
                parent.image = original
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
