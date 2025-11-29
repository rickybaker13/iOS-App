import SwiftUI
import AVFoundation
import UIKit

fileprivate final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer")
        }
        return layer
    }
}

fileprivate struct CameraView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.backgroundColor = .black
        
        let previewLayer = view.previewLayer
        previewLayer.session = cameraManager.captureSession
        previewLayer.videoGravity = .resizeAspectFill
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        let previewLayer = uiView.previewLayer
        if previewLayer.session !== cameraManager.captureSession {
            previewLayer.session = cameraManager.captureSession
        }
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        previewLayer.frame = uiView.bounds
    }
}

// UIKit button wrapper - completely isolated to avoid any SwiftUI evaluation issues
fileprivate struct CaptureButtonView: UIViewRepresentable {
    let onTap: () -> Void
    
    func makeUIView(context: Context) -> UIButton {
        print("CaptureButtonView: makeUIView called")
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.black.cgColor
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        
        // Store coordinator reference directly in button
        let coordinator = Coordinator(onTap: onTap)
        objc_setAssociatedObject(button, &AssociatedKeys.coordinator, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        button.addTarget(coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        print("CaptureButtonView: Button created and target added")
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        // Update coordinator's onTap if needed
        if let coordinator = objc_getAssociatedObject(uiView, &AssociatedKeys.coordinator) as? Coordinator {
            coordinator.onTap = onTap
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    class Coordinator: NSObject {
        var onTap: () -> Void
        
        init(onTap: @escaping () -> Void) {
            print("CaptureButtonView Coordinator: init")
            self.onTap = onTap
            super.init()
        }
        
        @objc func buttonTapped() {
            print("UIKit Coordinator: buttonTapped called - START")
            onTap()
            print("UIKit Coordinator: buttonTapped called - END")
        }
    }
}

// Associated object key for storing coordinator
private struct AssociatedKeys {
    static var coordinator = "coordinator"
}

// Isolated capture button view that doesn't access any properties
fileprivate struct IsolatedCaptureButton: View {
    let onTap: () -> Void
    
    var body: some View {
        CaptureButtonView(onTap: onTap)
            .frame(width: 80, height: 80)
    }
}

struct VisualCaptureView: View {
    let lectureId: UUID
    @StateObject private var visualAssistant: VisualLectureAssistant
    @ObservedObject private var cameraManager: CameraManager
    @State private var showingImageAnalysis = false
    @State private var selectedImage: LectureImage?
    @State private var questionText = ""
    @State private var showingSettings = false
    @State private var showingLogs = false
    @State private var triggerCapture = false
    @Environment(\.dismiss) var dismiss
    @State private var showStartupOverlay = false
    @State private var sessionStartObserver: NSObjectProtocol?
    @State private var sessionStopObserver: NSObjectProtocol?
    @EnvironmentObject private var dataManager: DataManager
    
    init(lectureId: UUID, visualAssistant: VisualLectureAssistant? = nil) {
        self.lectureId = lectureId
        let resolvedAssistant = visualAssistant ?? VisualLectureAssistant()
        _visualAssistant = StateObject(wrappedValue: resolvedAssistant)
        _cameraManager = ObservedObject(wrappedValue: resolvedAssistant.cameraManager)
    }
    
    private var lectureImages: [LectureImage] {
        visualAssistant.getImagesForLecture(lectureId)
    }
    
    // Separate function for capture button action to avoid closure capture issues
    @MainActor
    private func handleCaptureButtonPress() {
        print("VisualCaptureView: handleCaptureButtonPress called - START")
        defer {
            print("VisualCaptureView: handleCaptureButtonPress called - END")
        }
        
        // Wrap everything in do-catch to catch any crashes
        do {
            let assistant = visualAssistant
            print("VisualCaptureView: Got visualAssistant")
            let manager = cameraManager
            print("VisualCaptureView: Got cameraManager")
            let lecture = lectureId
            print("VisualCaptureView: Got lectureId")
            
            print("VisualCaptureView: Capture button ACTION triggered - step 1")
            
            guard !assistant.isCapturing else {
                print("VisualCaptureView: Already capturing, ignoring")
                manager.recordLog("VisualCaptureView: Already capturing, ignoring")
                return
            }
            
            guard cameraManager.isSessionRunning else {
                print("VisualCaptureView: Session not running, cannot capture")
                cameraManager.recordLog("VisualCaptureView: Session not running, cannot capture")
                return
            }
            
            print("VisualCaptureView: All checks passed, creating Task")
            
            Task { @MainActor in
                print("VisualCaptureView: Starting capture task")
                cameraManager.recordLog("VisualCaptureView: Starting capture task")
                
                // Access dataManager inside Task where it's safe
                let dataMgr = dataManager
                
                do {
                    print("VisualCaptureView: Calling captureImage")
                    if let capturedImage = await assistant.captureImage(for: lecture) {
                        print("VisualCaptureView: Capture successful, image: \(capturedImage.imageFileName)")
                        cameraManager.recordLog("VisualCaptureView: Capture successful, image: \(capturedImage.imageFileName)")
                        
                        if dataMgr.lectureExists(lecture) {
                            print("VisualCaptureView: Adding image to DataManager")
                            cameraManager.recordLog("VisualCaptureView: Adding image to DataManager")
                            dataMgr.addLectureImages([capturedImage], to: lecture)
                        } else {
                            print("VisualCaptureView: Lecture \(lecture) does not exist yet")
                            cameraManager.recordLog("VisualCaptureView: Lecture \(lecture) does not exist yet")
                        }
                    } else {
                        print("VisualCaptureView: Capture returned nil")
                        cameraManager.recordLog("VisualCaptureView: Capture returned nil")
                    }
                } catch {
                    print("VisualCaptureView: Capture task error: \(error)")
                cameraManager.recordLog("VisualCaptureView: Capture task error: \(error.localizedDescription)")
                }
            }
        } catch {
            print("VisualCaptureView: Fatal error in handleCaptureButtonPress: \(error)")
            cameraManager.recordLog("VisualCaptureView: Fatal error: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        // DON'T access cameraManager in body - it might be causing the crash
        // Access it only when needed in specific views
        return NavigationView {
            ZStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    // Camera preview fades in when the session is really running
                    if cameraManager.isSessionRunning {
                        CameraView(cameraManager: cameraManager)
                            .ignoresSafeArea()
                    }
                    
                    // Lightweight overlays only when needed
                    Group {
                        switch cameraManager.authorizationStatus {
                        case .authorized:
                            if let error = cameraManager.error {
                                ErrorOverlayView(
                                    title: "Camera Error",
                                    message: error,
                                    primaryAction: ("View Logs", { showingLogs = true })
                                )
                            } else if !cameraManager.isSessionRunning && showStartupOverlay {
                                StartupOverlayView(
                                    title: "Preparing camera…",
                                    primaryAction: ("Retry", {
                                        cameraManager.checkAuthorization()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            visualAssistant.startCamera()
                                        }
                                    }),
                                    secondaryAction: ("View Logs", { showingLogs = true })
                                )
                            }
                        case .notDetermined:
                            StartupOverlayView(
                                title: "Requesting camera access…",
                                showButtons: false
                            )
                        case .denied:
                            ErrorOverlayView(
                                title: "Camera access denied",
                                message: "Enable camera access in Settings to capture lecture visuals.",
                                primaryAction: ("Open Settings", {
                                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsURL)
                                    }
                                })
                            )
                        case .restricted:
                            ErrorOverlayView(
                                title: "Camera access restricted",
                                message: "Camera usage is restricted on this device."
                            )
                        @unknown default:
                            ErrorOverlayView(
                                title: "Unable to access camera",
                                message: "Unknown authorization status."
                            )
                        }
                    }
                }
                
                // Overlay controls
                VStack {
                    // Top controls
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            showingLogs = true
                        }) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding(.trailing, 8)
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 20) {
                        // Capture button triggers a state change that runs the capture logic
                        Button(action: {
                            print("VisualCaptureView: CAPTURE BUTTON PRESSED - START")
                            cameraManager.recordLog("VisualCaptureView: CAPTURE BUTTON PRESSED")
                            
                            print("VisualCaptureView: Setting triggerCapture")
                            triggerCapture = true
                            print("VisualCaptureView: triggerCapture set, CAPTURE BUTTON PRESSED - END")
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .stroke(Color.black, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                            }
                        }
                        .onAppear {
                            print("VisualCaptureView: Capture button appeared")
                            cameraManager.recordLog("VisualCaptureView: Capture button appeared")
                        }
                        
                        // Captured images preview
                        if !lectureImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(lectureImages) { image in
                                        Button(action: {
                                            selectedImage = image
                                            showingImageAnalysis = true
                                        }) {
                                            if let uiImage = visualAssistant.loadImage(named: image.imageFileName, lectureId: lectureId) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.gray)
                                                    .frame(width: 60, height: 60)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 80)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onChange(of: triggerCapture) { newValue in
            print("onChange: triggerCapture = \(newValue)")
            guard newValue else { return }
            
            // Reset immediately to prevent re-triggering
            triggerCapture = false
            
            // Call capture directly - don't use separate function to avoid any closure issues
            print("onChange: About to call capture directly")
            Task { @MainActor in
                print("onChange: Inside Task, calling handleCaptureButtonPress")
                handleCaptureButtonPress()
                print("onChange: handleCaptureButtonPress completed")
            }
        }
        .onAppear {
            let mgr = cameraManager
            print("VisualCaptureView: Appeared, checking camera authorization")
            print("VisualCaptureView: Camera authorized: \(mgr.isAuthorized)")
            print("VisualCaptureView: Authorization status: \(mgr.authorizationStatus.rawValue)")
            
            showStartupOverlay = false
            
            let storedImages = dataManager.getLectureImages(for: lectureId)
            if !storedImages.isEmpty {
                visualAssistant.seedImages(storedImages)
            }
            
            // Re-check authorization in case it changed
            mgr.checkAuthorization()
            
            // Give a small delay for authorization to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("VisualCaptureView: Starting camera after authorization check")
                visualAssistant.startCamera()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if !cameraManager.isSessionRunning {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showStartupOverlay = true
                    }
                }
            }
            
            if sessionStartObserver != nil {
                NotificationCenter.default.removeObserver(sessionStartObserver!)
            }
            sessionStartObserver = NotificationCenter.default.addObserver(
                forName: .AVCaptureSessionDidStartRunning,
                object: nil,
                queue: .main
            ) { [weak cameraManager] _ in
                print("VisualCaptureView: AVCaptureSessionDidStartRunning received")
                cameraManager?.isSessionRunning = true
                withAnimation(.easeInOut(duration: 0.25)) {
                    showStartupOverlay = false
                }
            }
            
            if sessionStopObserver != nil {
                NotificationCenter.default.removeObserver(sessionStopObserver!)
            }
            sessionStopObserver = NotificationCenter.default.addObserver(
                forName: .AVCaptureSessionDidStopRunning,
                object: nil,
                queue: .main
            ) { [weak cameraManager, weak visualAssistant] _ in
                print("VisualCaptureView: AVCaptureSessionDidStopRunning received")
                cameraManager?.isSessionRunning = false
                guard let assistant = visualAssistant else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    assistant.startCamera()
                }
            }
        }
        .onDisappear {
            visualAssistant.stopCamera()
            showStartupOverlay = false
            if let observer = sessionStartObserver {
                NotificationCenter.default.removeObserver(observer)
                sessionStartObserver = nil
            }
            if let observer = sessionStopObserver {
                NotificationCenter.default.removeObserver(observer)
                sessionStopObserver = nil
            }
        }
        .sheet(isPresented: $showingImageAnalysis) {
            if let image = selectedImage {
                ImageAnalysisView(
                    lectureImage: image,
                    visualAssistant: visualAssistant
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            VisualSettingsView(visualAssistant: visualAssistant)
        }
        .sheet(isPresented: $showingLogs) {
            LogViewerView(
                logs: cameraManager.logMessages,
                onClear: {
                    cameraManager.logMessages.removeAll()
                }
            )
        }
        .alert("Error", isPresented: .constant(visualAssistant.error != nil)) {
            Button("OK") {
                visualAssistant.error = nil
            }
        } message: {
            Text(visualAssistant.error ?? "")
        }
    }
}

private struct LogViewerView: View {
    let logs: [String]
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if logs.isEmpty {
                        Text("No logs yet. Try re-opening the camera to generate diagnostic messages.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(logs, id: \.self) { log in
                            Text(log)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Camera Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        onClear()
                    }
                    .disabled(logs.isEmpty)
                }
            }
        }
    }
}

private struct StartupOverlayView: View {
    let title: String
    var primaryAction: (String, () -> Void)?
    var secondaryAction: (String, () -> Void)?
    var showButtons: Bool = true
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.1)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if showButtons {
                VStack(spacing: 8) {
                    if let primary = primaryAction {
                        Button(primary.0) {
                            primary.1()
                        }
                        .buttonStyle(OverlayButtonStyle(filled: true))
                    }
                    if let secondary = secondaryAction {
                        Button(secondary.0) {
                            secondary.1()
                        }
                        .buttonStyle(OverlayButtonStyle(filled: false))
                    }
                }
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.55))
        .cornerRadius(18)
        .padding(.horizontal, 30)
    }
}

private struct ErrorOverlayView: View {
    let title: String
    var message: String
    var primaryAction: (String, () -> Void)?
    var secondaryAction: (String, () -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                if let primary = primaryAction {
                    Button(primary.0) {
                        primary.1()
                    }
                    .buttonStyle(OverlayButtonStyle(filled: true))
                }
                if let secondary = secondaryAction {
                    Button(secondary.0) {
                        secondary.1()
                    }
                    .buttonStyle(OverlayButtonStyle(filled: false))
                }
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.6))
        .cornerRadius(18)
        .padding(.horizontal, 30)
    }
}

private struct OverlayButtonStyle: ButtonStyle {
    let filled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(filled ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                (filled ? Color.white : Color.white.opacity(0.2))
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
            .cornerRadius(10)
    }
}


struct ImageAnalysisView: View {
    let lectureImage: LectureImage
    @ObservedObject var visualAssistant: VisualLectureAssistant
    @State private var questionText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Image display
                if let uiImage = visualAssistant.loadImage(named: lectureImage.imageFileName, lectureId: lectureImage.lectureId) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Question input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ask about this image:")
                        .font(.headline)
                    
                    TextField("e.g., What equation is this? How do I solve it?", text: $questionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Analysis button
                Button(action: {
                    Task {
                        await visualAssistant.analyzeImage(lectureImage, question: questionText)
                    }
                }) {
                    HStack {
                        if visualAssistant.isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(visualAssistant.isAnalyzing ? "Analyzing..." : "Analyze Image")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.matePrimary)
                    .cornerRadius(10)
                }
                .disabled(questionText.isEmpty || visualAssistant.isAnalyzing)
                .padding(.horizontal)
                
                // Analysis result
                if !visualAssistant.currentAnalysis.isEmpty {
                    ScrollView {
                        Text(visualAssistant.currentAnalysis)
                            .padding()
                            .background(Color.mateSecondary.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Image Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VisualSettingsView: View {
    @ObservedObject var visualAssistant: VisualLectureAssistant
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Storage")) {
                    Picker("Storage Location", selection: $visualAssistant.storagePreference) {
                        ForEach(StoragePreference.allCases, id: \.self) { preference in
                            Text(preference.displayName).tag(preference)
                        }
                    }
                    .onChange(of: visualAssistant.storagePreference) { newValue in
                        visualAssistant.updateStoragePreference(newValue)
                    }
                }
                
                Section(header: Text("About")) {
                    Text("Visual Lecture Assistant uses GPT-4V to analyze images from your lectures. Images are stored locally on your device for privacy.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 