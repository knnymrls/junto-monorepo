//
//  ImagePreviewView.swift
//  mkrs-world
//
//  Preview component for selected images with remove button and loading overlay
//

import SwiftUI
import UIKit

struct ImagePreviewView: View {
    let image: UIImage
    var isUploading: Bool = false
    var onRemove: (() -> Void)?
    var size: CGFloat = 200
    var cornerRadius: CGFloat = 11
    var closeButtonSize: CGFloat = 24
    var closeButtonPadding: CGFloat = 8
    var compact: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if compact {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipped()
                    .cornerRadius(cornerRadius)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: size)
                    .cornerRadius(cornerRadius)
            }

            // Loading overlay
            if isUploading {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.5))
                    .frame(
                        width: compact ? size : nil,
                        height: compact ? size : nil
                    )
                    .overlay(
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(compact ? 0.8 : 1.0)
                    )
            }

            // Remove button
            if !isUploading, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: closeButtonSize))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
                .padding(closeButtonPadding)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ImagePreviewView(
            image: UIImage(systemName: "photo.fill")!,
            isUploading: false,
            onRemove: {}
        )

        ImagePreviewView(
            image: UIImage(systemName: "photo.fill")!,
            isUploading: true
        )

        HStack {
            ImagePreviewView(
                image: UIImage(systemName: "photo.fill")!,
                onRemove: {},
                size: 80,
                cornerRadius: 8,
                closeButtonSize: 18,
                closeButtonPadding: 4,
                compact: true
            )
            Spacer()
        }
    }
    .padding()
}
