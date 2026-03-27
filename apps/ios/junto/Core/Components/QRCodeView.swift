//
//  QRCodeView.swift
//  mkrs-world
//
//  Generate QR code from data string
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let data: String
    var foregroundColor: Color = .appPrimary
    var backgroundColor: Color = .appSurface

    var body: some View {
        Image(uiImage: generateQRCode(from: data))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }

    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }

        // Scale up the QR code
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }

        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRCodeView(data: "junto://connect/123")
        .frame(width: 200, height: 200)
        .padding()
}
