//
//  ImageAmbientColor.swift
//  junto
//
//  Derives a tint color from an image so views can build an ambient backdrop
//  that shifts to match an uploaded photo (used by the create-event sheet).
//

import UIKit
import CoreImage

extension UIImage {
    /// The image's average color (1px CIAreaAverage downsample).
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extent = inputImage.extent
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: inputImage,
            kCIInputExtentKey: CIVector(cgRect: extent),
        ]), let output = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )
    }

    /// A saturated, mid-dark version of the average color — reads as a vivid
    /// ambient backdrop while keeping white text legible on top.
    var ambientColor: UIColor? {
        guard let avg = averageColor else { return nil }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard avg.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return avg }
        return UIColor(
            hue: h,
            saturation: min(s * 1.7, 1.0),
            brightness: max(min(b, 0.5), 0.28),
            alpha: 1
        )
    }
}
