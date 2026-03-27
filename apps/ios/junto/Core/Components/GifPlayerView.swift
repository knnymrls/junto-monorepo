//
//  GifPlayerView.swift
//  mkrs-world
//
//  Looping mp4 player for inline GIF display — self-sizes to native aspect ratio
//

import SwiftUI
import AVFoundation

struct GifPlayerView: View {
    let url: URL

    @State private var aspectRatio: CGFloat? = nil

    var body: some View {
        _GifPlayerRepresentable(url: url, onAspectRatio: { ratio in
            if aspectRatio == nil { aspectRatio = ratio }
        })
        .aspectRatio(aspectRatio ?? 1.5, contentMode: .fit)
    }
}

// MARK: - UIViewRepresentable

private struct _GifPlayerRepresentable: UIViewRepresentable {
    let url: URL
    let onAspectRatio: (CGFloat) -> Void

    func makeUIView(context: Context) -> GifPlayerUIView {
        GifPlayerUIView(url: url, onAspectRatio: onAspectRatio)
    }

    func updateUIView(_ uiView: GifPlayerUIView, context: Context) {
        uiView.updateURL(url, onAspectRatio: onAspectRatio)
    }
}

class GifPlayerUIView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var loopObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var currentURL: URL?

    init(url: URL, onAspectRatio: @escaping (CGFloat) -> Void) {
        super.init(frame: .zero)
        clipsToBounds = true
        setupPlayer(url: url, onAspectRatio: onAspectRatio)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateURL(_ url: URL, onAspectRatio: @escaping (CGFloat) -> Void) {
        guard url != currentURL else { return }
        cleanup()
        setupPlayer(url: url, onAspectRatio: onAspectRatio)
    }

    private func setupPlayer(url: URL, onAspectRatio: @escaping (CGFloat) -> Void) {
        currentURL = url

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        player.allowsExternalPlayback = false

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        self.layer.addSublayer(layer)

        self.player = player
        self.playerLayer = layer

        // Read natural video size once ready
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            self?.statusObserver = nil
            if let track = item.asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize.applying(track.preferredTransform)
                let w = abs(size.width)
                let h = abs(size.height)
                if h > 0 {
                    DispatchQueue.main.async {
                        onAspectRatio(w / h)
                    }
                }
            }
        }

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        player.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    private func cleanup() {
        player?.pause()
        statusObserver?.invalidate()
        statusObserver = nil
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        currentURL = nil
    }

    deinit {
        cleanup()
    }
}
