//
//  Typography.swift
//  mkrs-world
//
//  Design system font scale
//

import SwiftUI

extension Font {
    // Bricolage Grotesque
    static let juntoDisplay = Font.custom("BricolageGrotesque-96ptExtraBold_ExtraBold", size: 64)
    static let juntoHeading = Font.custom("BricolageGrotesque-96ptExtraBold_SemiBold", size: 24)

    // Display
    static let displayLarge = Font.system(size: 48, weight: .bold)
    static let displayMedium = Font.system(size: 32, weight: .bold)

    // Headings
    static let heading1 = Font.system(size: 24, weight: .semibold)
    static let heading2 = Font.system(size: 20, weight: .semibold)
    static let heading3 = Font.system(size: 18, weight: .semibold)
    static let heading3Regular = Font.system(size: 18, weight: .regular)

    // Body
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyLargeSemibold = Font.system(size: 16, weight: .semibold)
    static let bodyLargeMedium = Font.system(size: 16, weight: .medium)
    static let bodyLargeBold = Font.system(size: 16, weight: .bold)
    static let body14 = Font.system(size: 14, weight: .regular)
    static let bodySemibold = Font.system(size: 14, weight: .semibold)
    static let bodyMedium = Font.system(size: 14, weight: .medium)
    static let bodyBold = Font.system(size: 14, weight: .bold)
    static let bodySmall = Font.system(size: 13, weight: .regular)
    static let bodySmallSemibold = Font.system(size: 13, weight: .semibold)
    static let bodySmallMedium = Font.system(size: 13, weight: .medium)

    // Caption
    static let caption12 = Font.system(size: 12, weight: .regular)
    static let captionSemibold = Font.system(size: 12, weight: .semibold)
    static let captionMedium = Font.system(size: 12, weight: .medium)
    static let captionSmall = Font.system(size: 11, weight: .regular)
    static let captionSmallMedium = Font.system(size: 11, weight: .medium)
    static let captionSmallSemibold = Font.system(size: 11, weight: .semibold)

    // Micro
    static let micro = Font.system(size: 10, weight: .regular)
    static let microMedium = Font.system(size: 10, weight: .medium)
    static let microSemibold = Font.system(size: 10, weight: .semibold)
    static let microBold = Font.system(size: 10, weight: .bold)
}
