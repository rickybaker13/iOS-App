import AVFoundation
import UIKit
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var error: String?
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var logMessages: [String] = []
    
    private func log(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let entry = "[\(timestamp)] \(message)"
        DispatchQueue.main.async {
            self.logMessages.append(entry)
            if self.logMessages.count > 200 {
                self.logMessages.removeFirst(self.logMessages.count - 200)
            }
        }
        print(message)
    }
    
    func recordLog(_ message: String) {
        log(message)
    }
    
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "CameraSessionQueue")
    private var isSessionConfigured = false
    
    // Public accessor for the session
    var captureSession: AVCaptureSession {
        return session
    }
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var activePhotoCaptureDelegates: [UUID: PhotoCaptureDelegate] = [:]
    private var isCapturingPhoto = false
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        log("CameraManager: Current authorization status: \(status.rawValue)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .authorized:
            log("CameraManager: Camera authorized, setting up session")
            DispatchQueue.main.async {
                self.isAuthorized = true
                self.error = nil
                self.authorizationStatus = .authorized
                self.setupSession()
            }
        case .notDetermined:
            log("CameraManager: Requesting camera access")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                self.log("CameraManager: Camera access granted: \(granted)")
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    if granted {
                        self.error = nil
                        self.authorizationStatus = .authorized
                        self.setupSession()
                    } else {
                        self.error = "Camera access was denied"
                        self.authorizationStatus = .denied
                    }
                }
            }
        case .denied:
            log("CameraManager: Camera access denied")
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = "Camera access is denied. Please enable it in Settings > StudyHack.ai > Camera"
                self.authorizationStatus = .denied
            }
        case .restricted:
            log("CameraManager: Camera access restricted")
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = "Camera access is restricted"
                self.authorizationStatus = .restricted
            }
        @unknown default:
            log("CameraManager: Unknown authorization status")
            DispatchQueue.main.async {
                self.isAuthorized = false
                self.error = "Unknown camera authorization status"
                self.authorizationStatus = status
            }
        }
    }
    
    private func setupSession() {
        sessionQueue.async {
            if self.isSessionConfigured {
                self.log("CameraManager: Session already configured, attempting to start")
                self.startSession()
                return
            }
            
            guard self.isAuthorized else {
                self.log("CameraManager: Not authorized to setup session")
                return
            }
            
            self.log("CameraManager: Setting up camera session (thread: \(Thread.isMainThread ? "main" : "background"))")
            self.session.beginConfiguration()
            
            if self.session.canSetSessionPreset(.photo) {
                self.session.sessionPreset = .photo
            }
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                self.log("CameraManager: Failed to get video device")
                DispatchQueue.main.async {
                    self.error = "Unable to access camera"
                }
                self.session.commitConfiguration()
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                    self.log("CameraManager: Video input added successfully (inputs: \(self.session.inputs.count))")
                } else {
                    self.log("CameraManager: Cannot add video input to session")
                    DispatchQueue.main.async {
                        self.error = "Cannot configure camera input"
                    }
                }
            } catch {
                self.log("CameraManager: Error creating video input: \(error)")
                DispatchQueue.main.async {
                    self.error = "Unable to initialize camera: \(error.localizedDescription)"
                }
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
                if #available(iOS 16.0, *) {
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                }
                self.log("CameraManager: Photo output added successfully (outputs: \(self.session.outputs.count))")
            } else {
                self.log("CameraManager: Cannot add photo output to session")
            }
            
            self.session.commitConfiguration()
            self.isSessionConfigured = true
            self.log("CameraManager: Camera session setup complete")
            
            self.startSession()
        }
    }
    
    func startSession() {
        sessionQueue.async {
            guard self.isAuthorized else {
                self.log("CameraManager: Cannot start session, not authorized")
                return
            }
            
            guard !self.session.isRunning else {
                self.log("CameraManager: Session already running")
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                    self.error = nil
                }
                return
            }
            
            self.log("CameraManager: Starting camera session")
            self.session.startRunning()
            let isRunning = self.session.isRunning
            self.log("CameraManager: session.startRunning() called, session.isRunning=\(isRunning)")
            DispatchQueue.main.async {
                self.isSessionRunning = isRunning
                self.error = isRunning ? nil : "Camera session failed to start"
                if isRunning {
                    self.log("CameraManager: Camera session is now running on main thread")
                } else {
                    self.log("CameraManager: Camera session failed to start")
                }
            }
            
            // Double-check after a short delay
            self.sessionQueue.asyncAfter(deadline: .now() + 0.5) {
                let runningLater = self.session.isRunning
                self.log("CameraManager: Session running check after delay: \(runningLater)")
                DispatchQueue.main.async {
                    self.isSessionRunning = runningLater
                    if runningLater {
                        self.error = nil
                    }
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
                self.log("CameraManager: Session stopped")
            }
        }
    }
    
    func capturePhoto() async throws -> UIImage {
        log("CameraManager: capturePhoto() called")
        guard isSessionRunning else {
            log("CameraManager: capturePhoto failed - session not running")
            throw CameraError.sessionNotRunning
        }
        
        guard !isCapturingPhoto else {
            log("CameraManager: Already capturing a photo, please wait")
            throw CameraError.alreadyCapturing
        }
        
        log("CameraManager: Session is running, creating photo settings")
        isCapturingPhoto = true
        
        defer {
            // Safety net: reset flag if we return without delegate completing
            // This will be overridden by the delegate's onComplete callback
            log("CameraManager: capturePhoto() defer block - will reset flag if delegate hasn't")
        }
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                // Create basic photo settings - prefer HEVC if available
                let settings: AVCapturePhotoSettings
                if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                    settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                } else {
                    settings = AVCapturePhotoSettings()
                }
                
                if photoOutput.isHighResolutionCaptureEnabled {
                    settings.isHighResolutionPhotoEnabled = true
                }
                
                log("CameraManager: Photo settings created, uniqueID=\(settings.uniqueID)")
                log("CameraManager: Photo output ready: capturing")
                
                let delegateId = UUID()
                log("CameraManager: Creating delegate with ID: \(delegateId)")
                let delegate = PhotoCaptureDelegate(
                    id: delegateId,
                    continuation: continuation,
                    logCallback: { [weak self] message in
                        self?.log(message)
                    },
                    onComplete: { [weak self] completedId in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            self.activePhotoCaptureDelegates.removeValue(forKey: completedId)
                            self.isCapturingPhoto = false
                            self.log("CameraManager: Delegate \(completedId) removed after completion, isCapturingPhoto=\(self.isCapturingPhoto)")
                        }
                    }
                )
                
                // Retain the delegate until capture completes
                activePhotoCaptureDelegates[delegateId] = delegate
                log("CameraManager: Delegate stored, total active delegates: \(activePhotoCaptureDelegates.count)")
                
                // capturePhoto must be called on the session queue
                sessionQueue.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.log("CameraManager: Calling photoOutput.capturePhoto() on session queue")
                    self.photoOutput.capturePhoto(with: settings, delegate: delegate)
                    self.log("CameraManager: capturePhoto() request submitted")
                }
            }
        } catch {
            // Reset flag on any error
            log("CameraManager: capturePhoto() error caught: \(error.localizedDescription), resetting flag")
            isCapturingPhoto = false
            throw error
        }
    }
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let id: UUID
    private let continuation: CheckedContinuation<UIImage, Error>
    private let logCallback: (String) -> Void
    private let onComplete: (UUID) -> Void
    private var hasResumed = false
    
    init(id: UUID, continuation: CheckedContinuation<UIImage, Error>, logCallback: @escaping (String) -> Void, onComplete: @escaping (UUID) -> Void) {
        self.id = id
        self.continuation = continuation
        self.logCallback = logCallback
        self.onComplete = onComplete
        super.init()
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Initialized")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: willBeginCaptureFor called, uniqueID=\(resolvedSettings.uniqueID)")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: willCapturePhotoFor called")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: didFinishProcessingPhoto called, error: \(error?.localizedDescription ?? "none")")
        
        guard !hasResumed else {
            logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Already resumed, ignoring duplicate callback")
            return
        }
        
        if let error = error {
            logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Error processing photo: \(error.localizedDescription)")
            hasResumed = true
            onComplete(id)
            continuation.resume(throwing: error)
            return
        }
        
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Getting fileDataRepresentation")
        guard let imageData = photo.fileDataRepresentation() else {
            logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Failed to get fileDataRepresentation")
            hasResumed = true
            onComplete(id)
            continuation.resume(throwing: CameraError.invalidImageData)
            return
        }
        
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Image data size: \(imageData.count) bytes")
        guard let image = UIImage(data: imageData) else {
            logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Failed to create UIImage from data")
            hasResumed = true
            onComplete(id)
            continuation.resume(throwing: CameraError.invalidImageData)
            return
        }
        
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Successfully created UIImage, resuming continuation")
        hasResumed = true
        onComplete(id)
        continuation.resume(returning: image)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: didFinishCaptureFor called, error: \(error?.localizedDescription ?? "none")")
        if let error = error, !hasResumed {
            logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: Capture finished with error: \(error.localizedDescription)")
            hasResumed = true
            onComplete(id)
            continuation.resume(throwing: error)
        } else if !hasResumed {
            logCallback("PhotoCaptureDelegate[\(id.uuidString.prefix(8))]: didFinishCaptureFor called but didFinishProcessingPhoto never fired - this is unusual")
        }
    }
}

// MARK: - Camera Error
enum CameraError: Error, LocalizedError {
    case sessionNotRunning
    case invalidImageData
    case authorizationDenied
    case alreadyCapturing
    
    var errorDescription: String? {
        switch self {
        case .sessionNotRunning:
            return "Camera session is not running"
        case .invalidImageData:
            return "Failed to process captured image"
        case .authorizationDenied:
            return "Camera access is required"
        case .alreadyCapturing:
            return "A photo capture is already in progress"
        }
    }
} 