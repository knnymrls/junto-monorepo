//
//  SemesterWheelPicker.swift
//  junto
//
//  Custom snap-scroll wheel picker with 3D barrel rotation,
//  haptic feedback, and tick sound on each notch
//

import SwiftUI
import AudioToolbox

struct SemesterWheelPicker: View {
    @Binding var selection: String
    let options: [String]

    @State private var scrolledTo: String?
    @State private var hasScrolledToInitial = false

    private let itemHeight: CGFloat = 40
    private let visibleCount = 7
    private let haptic = UISelectionFeedbackGenerator()

    var body: some View {
        let totalHeight = itemHeight * CGFloat(visibleCount)

        ZStack {
            RoundedRectangle(cornerRadius: Radius.xxl)
                .fill(Color.appInputFill)
                .frame(width: 293, height: itemHeight + 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: itemHeight * CGFloat(visibleCount / 2))

                    ForEach(options, id: \.self) { option in
                        GeometryReader { itemGeo in
                            let midY = itemGeo.frame(in: .named("wheel")).midY
                            let centerY = totalHeight / 2
                            let offset = midY - centerY
                            let maxOffset = itemHeight * CGFloat(visibleCount / 2)
                            let normalizedOffset = offset / maxOffset
                            let clampedOffset = min(max(normalizedOffset, -1), 1)

                            let angle = Angle.degrees(Double(clampedOffset) * 60)
                            let scale = 1.0 - (abs(Double(clampedOffset)) * 0.25)
                            let opacity = 1.0 - (abs(Double(clampedOffset)) * 0.75)
                            let yShift = sin(Double(clampedOffset) * .pi / 2) * 8
                            let isCenter = abs(offset) < itemHeight / 2

                            Text(option)
                                .font(.system(size: isCenter ? 24 : 20, weight: .semibold))
                                .foregroundColor(isCenter ? .appPrimary : .appSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: itemHeight)
                                .rotation3DEffect(angle, axis: (x: 1, y: 0, z: 0), perspective: 0.5)
                                .scaleEffect(scale)
                                .opacity(opacity)
                                .offset(y: yShift)
                                .onChange(of: isCenter) { _, selected in
                                    if selected && hasScrolledToInitial {
                                        selection = option
                                        haptic.selectionChanged()
                                        AudioServicesPlaySystemSound(1104)
                                    }
                                }
                        }
                        .frame(height: itemHeight)
                        .id(option)
                    }

                    Color.clear.frame(height: itemHeight * CGFloat(visibleCount / 2))
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledTo, anchor: .center)
            .coordinateSpace(name: "wheel")
            .frame(height: totalHeight)
        }
        .frame(height: totalHeight)
        .onAppear {
            haptic.prepare()
            scrolledTo = selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hasScrolledToInitial = true
            }
        }
    }
}
