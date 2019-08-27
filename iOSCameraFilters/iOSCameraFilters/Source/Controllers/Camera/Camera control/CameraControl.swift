//
//  CameraControl.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit
import AVFoundation

final class CameraControl: UIViewController {
    
    enum TorchMode: Int {
        case on, off, auto
    }
    
    enum Autofocus: Int {
        case on, off
    }
    
    private enum AuthorizationStatus {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    // MARK: - Camera control variables
    var position: AVCaptureDevice.Position = .back {
        didSet {
            if cameraPositionChanging == true {
                position = oldValue
            } else {
                setCameraPosition(position)
            }
        }
    }
    
    var torchMode: TorchMode = .off {
        didSet {
            updateTorchMode()
        }
    }
    
    var flashlightEnabled: Bool {
        guard let cameraDevice = camera(with: position) else { return false }
        return cameraDevice.hasFlash && cameraDevice.isFlashAvailable
    }
    
    var autoFocus: Autofocus = .on {
        didSet {
            updateFocusMode()
        }
    }
    var videoFilter: CIFilter?
    
    // MARK: - Private
    private var cameraPositionChanging: Bool = false
    private var photoHandler: ((UIImage?, Error?) -> Void)?
    private var appName: String {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Unknown"
    }
    private var authorizationStatus: AuthorizationStatus = .success
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        
        return imageView
    }()
    // MARK: Session Management
    private let context = CIContext()
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera session queue")
    @objc dynamic var deviceInput: AVCaptureDeviceInput!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the video preview view.
        checkCameraAuthorizationStatus()
        
        // Configure views
        viewConfiguration()
        
        // Configure session
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async { [weak self] in
            switch self?.authorizationStatus {
            case .success?:
                self?.session.startRunning()
            case .notAuthorized?:
                self?.needSettingsAccessAlert()
            case .configurationFailed?:
                self?.showAlert("Unable to configurate media session.")
            case .none:
                break
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async { [weak self] in
            if self?.authorizationStatus == .success {
                self?.session.stopRunning()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        previewImageView.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
        previewLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height)
    }
}

// MARK: - Camera
extension CameraControl {
    private func checkCameraAuthorizationStatus(_ handler: (() -> Void)? = nil) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            handler?()
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                if !granted {
                    self?.authorizationStatus = .notAuthorized
                }
                self?.sessionQueue.resume()
                handler?()
            })
        default:
            authorizationStatus = .notAuthorized
            handler?()
        }
    }
    
    // Get camera device with position
    private func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if position == .back, let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        } else {
            print("Failed to get the camera device")
            return nil
        }
    }
    
    // Views configuration
    private func viewConfiguration() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        view.addSubview(previewImageView)
    }
    
    // Session configuration
    private func configureSession(_ retry: Bool? = false) {
        if authorizationStatus != .success && retry == false {
            return
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        // Add inputs for current active session
        do {
            guard let cameraDevice = camera(with: position) else {
                if retry == false {
                    showAlert("Device camera is unavailable.")
                } else {
                    needSettingsAccessAlert()
                }
                authorizationStatus = .configurationFailed
                return
            }
            let tempDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            
            if session.canAddInput(tempDeviceInput) {
                session.addInput(tempDeviceInput)
                deviceInput = tempDeviceInput
            } else {
                showAlert("Failed to add media capture device into an active session.")
                authorizationStatus = .configurationFailed
                return
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "output queue",
                                                                           qos: .userInitiated,
                                                                           attributes: [],
                                                                           autoreleaseFrequency: .workItem))
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
        } catch {
            showAlert("Failed while creating device input. Error: \(error)")
            authorizationStatus = .configurationFailed
            return
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            showAlert("Failed to add photo output to an active session.")
            authorizationStatus = .configurationFailed
            return
        }
    }
}

// MARK: - Device configuration changes
extension CameraControl {
    private func updateTorchMode() {
        if flashlightEnabled == false { return }
        guard let cameraDevice = camera(with: position) else { return }
        if cameraDevice.hasFlash {
            do {
                try cameraDevice.lockForConfiguration()
                var touchMode: AVCaptureDevice.TorchMode = .off
                
                switch torchMode {
                case .on:
                    touchMode = .on
                case .off:
                    touchMode = .off
                case .auto:
                    touchMode = .auto
                }
                if cameraDevice.isTorchModeSupported(touchMode) {
                    cameraDevice.torchMode = touchMode
                }
                
                cameraDevice.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    private func updateFocusMode() {
        focus(with: autoFocus == .on ? .continuousAutoFocus : .locked)
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode) {
        sessionQueue.async {
            guard let deviceInput = self.deviceInput else { return }
            let device = deviceInput.device
            if !device.isFocusModeSupported(focusMode) { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                }
                device.focusMode = focusMode
                device.isSubjectAreaChangeMonitoringEnabled = false
                device.unlockForConfiguration()
            } catch {
                self.showAlert("Device locked, but failed with configuration: \(error)")
            }
        }
    }
    
    private func capturePhotoSettings() -> AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings()
        if flashlightEnabled == false { return photoSettings }
        
        if deviceInput.device.isFlashAvailable {
            switch self.torchMode {
            case .on:
                photoSettings.flashMode = .on
            case .off:
                photoSettings.flashMode = .off
            case .auto:
                photoSettings.flashMode = .auto
            }
        }
        
        photoSettings.isHighResolutionPhotoEnabled = true
        if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first ?? NSNumber(value: 0)]
        }
        
        return photoSettings
    }
    
    private func setCameraPosition(_ position: AVCaptureDevice.Position, completion: (() -> Void)? = nil) {
        guard let cameraDevice = camera(with: position) else {
            return
        }
        
        do {
            guard let prevDeviceInput = deviceInput else { return }
            cameraPositionChanging = true
            deviceInput = try AVCaptureDeviceInput(device: cameraDevice)
            
            if self.session.inputs.contains(prevDeviceInput) {
                self.session.removeInput(prevDeviceInput)
            }
            UIView.transition(with: view, duration: 0.5, options: .curveEaseIn, animations: {
            }, completion: { finished in
                self.session.addInput(self.deviceInput)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.cameraPositionChanging = false
                })
            })
        } catch {
            showAlert("Failed while creating device input. Error: \(error)")
            return
        }
        
        updateFocusMode()
    }
}

// MARK: - Camera control alerts
extension CameraControl {
    private func needSettingsAccessAlert() {
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        let alertController = UIAlertController(title: appName, message: "\(appName) doesn't have permission to use the camera, please change privacy settings", preferredStyle: .alert)
        alertController.addAction(okAction)
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showAlert(_ message: String) {
        let alertController = UIAlertController(title: appName, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK",
                                                style: .cancel,
                                                handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Photo capture and Sample buffer process
extension CameraControl: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer)
        
        if let image = applyFilter(to: cameraImage) {
            DispatchQueue.main.async {
                self.previewImageView.image = image
            }
        }
    }
}

extension CameraControl: AVCapturePhotoCaptureDelegate {
    public func takePhoto(_ handler: @escaping(UIImage?, Error?) -> Void) {
        if deviceInput == nil {
            let error =  NSError(domain: NSStringFromClass(type(of: self)), code: 0, userInfo: [NSLocalizedDescriptionKey: "Camera input device not found"])
            handler(nil, error)
            return
        }
        
        photoHandler = handler
        takePhoto(capturePhotoSettings())
    }
    
    private func takePhoto(_ settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        sessionQueue.async {
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let cgImage = photo.cgImageRepresentation()?.takeUnretainedValue() else {
            photoHandler?(nil, error)
            return
        }
        
        let image = UIImage(cgImage: cgImage)
        if let _ = videoFilter {
            if let cgImage = image.cgImage, let filteredPhoto = applyFilter(to: CIImage(cgImage: cgImage)) {
                photoHandler?(crop(filteredPhoto), nil)
            } else {
                let error =  NSError(domain: NSStringFromClass(type(of: self)), code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage from UIImage"])
                photoHandler?(nil, error)
            }
        } else {
            photoHandler?(crop(image), nil)
        }
    }
    
    private func applyFilter(to image: CIImage) -> UIImage? {
        if let videoFilter = videoFilter {
            videoFilter.setValue(image, forKey: kCIInputImageKey)
            guard let outputImage = videoFilter.outputImage else { return nil }
            if let cgImage = context.createCGImage(outputImage, from: image.extent) {
                return UIImage(cgImage: cgImage)
            } else {
                return nil
            }
        }
        
        return UIImage(ciImage: image)
    }
    
    private func crop(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage, let previewLayer = previewLayer else { return image }
        let outputRect = previewLayer.metadataOutputRectConverted(fromLayerRect: previewLayer.bounds)
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let toRect = CGRect(x: outputRect.origin.x * width, y: outputRect.origin.y * height, width: outputRect.size.width * width, height: outputRect.size.height * height)
        
        guard let croppedCGImage = cgImage.cropping(to: toRect) else { return UIImage() }
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation).normalizeImage()
    }
}

// MARK: - UIImage extension
extension UIImage {
    fileprivate func normalizeImage() -> UIImage {
        var fixedImage = UIImage()
        if let cgImage = cgImage {
            switch imageOrientation {
            case .right:
                fixedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .down)
            case .down:
                fixedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .left)
            case .left:
                fixedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
            default:
                fixedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            }
        } else {
            switch imageOrientation {
            case .up:
                return self
            default:
                UIGraphicsBeginImageContextWithOptions(size, false, scale)
                draw(in: CGRect(origin: .zero, size: size))
                if let result = UIGraphicsGetImageFromCurrentImageContext() {
                    UIGraphicsEndImageContext()
                    fixedImage = result
                } else {
                    fixedImage = self
                }
            }
        }
        
        return fixedImage
    }
}
