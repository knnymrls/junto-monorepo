//
//  FullScreenImageView.swift
//  mkrs-world
//
//  Full screen image viewer — matched geometry open/close, horizontal paging, drag-to-dismiss
//

import SwiftUI
import UIKit

// MARK: - Namespace Environment Key

struct ImageNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var imageNamespace: Namespace.ID? {
        get { self[ImageNamespaceKey.self] }
        set { self[ImageNamespaceKey.self] = newValue }
    }
}

// MARK: - Image Viewer Manager

@MainActor
class ImageViewerManager: ObservableObject {
    static let shared = ImageViewerManager()

    @Published var imageUrls: [URL] = []
    @Published var currentIndex: Int = 0
    @Published var isPresented: Bool = false

    var selectedImageUrl: URL? {
        guard currentIndex >= 0 && currentIndex < imageUrls.count else { return nil }
        return imageUrls[currentIndex]
    }

    var selectedImageId: String? {
        selectedImageUrl?.absoluteString
    }

    func show(url: URL) {
        show(urls: [url], index: 0)
    }

    func show(urls: [URL], index: Int) {
        imageUrls = urls
        currentIndex = index
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isPresented = true
        }
    }

    func dismiss() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.imageUrls = []
            self.currentIndex = 0
        }
    }
}

// MARK: - Image Viewer Root

struct ImageViewerRoot<Content: View>: View {
    @Namespace private var imageNamespace
    @ObservedObject var manager = ImageViewerManager.shared
    @State private var dragY: CGFloat = 0
    @State private var isDragging = false
    @State private var showPaging = false
    @State private var scrolledID: String?
    @ViewBuilder let content: Content

    private var dragProgress: CGFloat { min(abs(dragY) / 300, 1.0) }
    private var dragScale: CGFloat { 1.0 - (dragProgress * 0.1) }
    private var cornerRadius: CGFloat { dragProgress * Radius.xxxl }

    var body: some View {
        ZStack {
            content
                .environment(\.imageNamespace, imageNamespace)

            if manager.isPresented, !manager.imageUrls.isEmpty {
                // Dimming background
                Color.black
                    .opacity(1.0 - min(dragProgress, 0.5))
                    .ignoresSafeArea()
                    .onTapGesture { dismissViewer() }
                    .transition(.opacity)

                // Image content — two phases
                Group {
                    if showPaging && manager.imageUrls.count > 1 {
                        pagingCarousel
                    } else if let url = manager.selectedImageUrl {
                        singleImage(url: url)
                    }
                }
                .offset(y: dragY)
                .scaleEffect(dragScale)
                .simultaneousGesture(dismissDrag)

                // Chrome: close button + page counter
                viewerChrome
                    .transition(.opacity)
            }
        }
        .onChange(of: manager.isPresented) { _, presented in
            if presented {
                // Set initial scroll position, then enable paging after open animation
                scrolledID = manager.selectedImageUrl?.absoluteString
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    showPaging = true
                }
            }
        }
        .onChange(of: scrolledID) { _, newID in
            // Sync scroll position back to manager
            guard let newID else { return }
            if let index = manager.imageUrls.firstIndex(where: { $0.absoluteString == newID }) {
                manager.currentIndex = index
            }
        }
    }

    // MARK: - Paging Carousel (horizontal scroll, one image per page, full width)

    private var pagingCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(manager.imageUrls, id: \.absoluteString) { url in
                    let isCurrent = url.absoluteString == scrolledID
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    } placeholder: {
                        ProgressView().tint(.white)
                    }
                    .containerRelativeFrame(.horizontal)
                    .opacity(isCurrent || !isDragging ? 1 : 0)
                    .id(url.absoluteString)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrolledID)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollDisabled(isDragging)
    }

    // MARK: - Single Image (matched geometry for open/close transitions)

    private func singleImage(url: URL) -> some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .matchedGeometryEffect(id: url.absoluteString, in: imageNamespace)
        } placeholder: {
            ProgressView().tint(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Dismiss Drag Gesture

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Lock direction on first movement
                if !isDragging {
                    guard abs(value.translation.height) > abs(value.translation.width) else { return }
                    isDragging = true
                }
                if isDragging {
                    dragY = value.translation.height
                }
            }
            .onEnded { value in
                if isDragging {
                    if abs(value.translation.height) > 100 || abs(value.predictedEndTranslation.height) > 200 {
                        dismissViewer()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragY = 0
                        }
                    }
                }
                isDragging = false
            }
    }

    // MARK: - Chrome (close button + page counter)

    private var viewerChrome: some View {
        VStack {
            HStack {
                if manager.imageUrls.count > 1 {
                    Text("\(manager.currentIndex + 1)/\(manager.imageUrls.count)")
                        .font(.captionSemibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                        .padding(.leading, 16)
                        .padding(.top, 16)
                }
                Spacer()
                Button(action: { dismissViewer() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
            Spacer()
        }
    }

    // MARK: - Dismiss

    private func dismissViewer() {
        // Switch back to single image for matched geometry close
        showPaging = false
        // Wait one frame for SwiftUI to render matched geometry image
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                dragY = 0
            }
            manager.dismiss()
        }
    }
}

// MARK: - Tappable Image (source side of matched geometry)

struct ExpandableImage<Content: View>: View {
    let url: URL
    let allUrls: [URL]
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    @Environment(\.imageNamespace) var namespace
    @ObservedObject var manager = ImageViewerManager.shared

    init(url: URL, cornerRadius: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.url = url
        self.allUrls = [url]
        self.cornerRadius = cornerRadius
        self.content = content
    }

    init(url: URL, allUrls: [URL], cornerRadius: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.url = url
        self.allUrls = allUrls
        self.cornerRadius = cornerRadius
        self.content = content
    }

    private var isSource: Bool {
        manager.selectedImageId != url.absoluteString || !manager.isPresented
    }

    var body: some View {
        if let ns = namespace {
            content()
                .matchedGeometryEffect(id: url.absoluteString, in: ns, isSource: isSource)
                .opacity(isSource ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    let index = allUrls.firstIndex(of: url) ?? 0
                    ImageViewerManager.shared.show(urls: allUrls, index: index)
                }
        } else {
            content()
                .cornerRadius(cornerRadius)
                .contentShape(Rectangle())
                .onTapGesture {
                    let index = allUrls.firstIndex(of: url) ?? 0
                    ImageViewerManager.shared.show(urls: allUrls, index: index)
                }
        }
    }
}

// MARK: - Legacy compatibility

struct ImageViewerOverlay: View {
    var body: some View { EmptyView() }
}

struct FullScreenImageView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CachedAsyncImage(url: url) { $0.resizable().aspectRatio(contentMode: .fit) } placeholder: { ProgressView().tint(.white) }
        }
        .onTapGesture { dismiss() }
    }
}

struct FullScreenUIImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: image).resizable().aspectRatio(contentMode: .fit)
        }
        .onTapGesture { dismiss() }
    }
}
