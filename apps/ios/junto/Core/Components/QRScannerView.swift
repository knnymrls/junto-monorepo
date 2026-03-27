//
//  QRScannerView.swift
//  mkrs-world
//
//  Camera scanner for QR codes using AVFoundation
//

#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
import AVFoundation

struct QRScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var scanner = QRScannerController()
    @State private var hasPermission = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if permissionDenied {
                    permissionDeniedView
                } else if hasPermission {
                    // Camera preview
                    CameraPreviewView(session: scanner.session)
                        .ignoresSafeArea()

                    // Scanning overlay
                    scanningOverlay
                } else {
                    // Loading state
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await checkPermission()
            }
            .onChange(of: scanner.scannedCode) { _, code in
                print("QRScannerView: scannedCode changed to: \(code ?? "nil")")
                if let code = code {
                    // Parse junto://connect/{userId} URL
                    if let userId = parseUserId(from: code) {
                        print("QRScannerView: Parsed userId: \(userId)")
                        onScan(userId)
                    }
                }
            }
        }
    }

    private var scanningOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            // Scanning frame
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 250, height: 250)
                .overlay(
                    ZStack {
                        CornerAccent().position(x: 20, y: 20)
                        CornerAccent().rotationEffect(.degrees(90)).position(x: 230, y: 20)
                        CornerAccent().rotationEffect(.degrees(180)).position(x: 230, y: 230)
                        CornerAccent().rotationEffect(.degrees(270)).position(x: 20, y: 230)
                    }
                )

            Text("Point camera at a user's QR code")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 20)

            Spacer()
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.5))

            Text("Camera Access Required")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("Enable camera access in Settings to scan QR codes")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: openSettings) {
                Text("Open Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
    }

    private func checkPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasPermission = true
            scanner.startScanning()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                hasPermission = granted
                permissionDenied = !granted
                if granted {
                    scanner.startScanning()
                }
            }
        case .denied, .restricted:
            permissionDenied = true
        @unknown default:
            permissionDenied = true
        }
    }

    private func parseUserId(from code: String) -> String? {
        // Parse junto://connect/{userId}
        if code.hasPrefix("junto://connect/") {
            return String(code.dropFirst("junto://connect/".count))
        }
        // Also accept raw user IDs for flexibility
        return code
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - QR Scanner Controller

class QRScannerController: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    let session = AVCaptureSession()
    private var isConfigured = false

    func startScanning() {
        guard !isConfigured else {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.configureSession()
        }
    }

    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    private func configureSession() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            let output = AVCaptureMetadataOutput()

            session.beginConfiguration()

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]

            session.commitConfiguration()
            isConfigured = true

            session.startRunning()
        } catch {
            print("QR Scanner error: \(error)")
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        print("QRScanner: metadataOutput called with \(metadataObjects.count) objects")

        guard let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadata.stringValue else {
            print("QRScanner: No valid QR code found")
            return
        }

        print("QRScanner: Detected code: \(code)")

        // Stop scanning after first successful read
        stopScanning()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        DispatchQueue.main.async {
            self.scannedCode = code
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = UIScreen.main.bounds
        }
    }
}

// MARK: - Corner Accent

struct CornerAccent: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 30, y: 0))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
    }
}

#Preview {
    QRScannerView { code in
        print("Scanned: \(code)")
    }
}
