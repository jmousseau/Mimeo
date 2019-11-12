//
//  CameraViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 9/29/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import AVFoundation
import Iris
import UIKit

/// The camera view controller delegate.
public protocol CameraViewControllerDelegate: class {

    /// The camera view controller captured a photo.
    /// - Parameter cameraViewController: The camera view controller which
    /// captured the `photo`.
    /// - Parameter photo: The captured photo.
    func cameraViewController(
        _ cameraViewController: CameraViewController,
        didCapturePhoto photo: AVCapturePhoto
    )

}

/// A camera view controller.
public final class CameraViewController: UIViewController {

    /// The camera view controller's delegate.
    public weak var delegate: CameraViewControllerDelegate?

    /// The last known device orientation that maps to a given user interface
    /// orientation.
    private var lastKnownDeviceOrientation: UIDeviceOrientation = .portrait {
        didSet {
            guard oldValue != lastKnownDeviceOrientation,
                let photoOutputConnection = photoOutput.connection(with: .video) else {
                return
            }

            photoOutputConnection.videoOrientation = lastKnownDeviceOrientation.videoOrientation
        }
    }

    // MARK: - View Controller Lifecycle

    public init() {
        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if requiredMediaType == .video {
            videoPreviewLayer = AVCaptureVideoPreviewLayer()
        }

        if let videoPreviewLayer = videoPreviewLayer {
            videoPreviewLayer.session = captureSession
            view.layer.addSublayer(videoPreviewLayer)
        }

        checkAuthorizationStatus()
        captureSessionQueue.async {
            self.configureCaptureSession()
        }

        let autoFocusGestureRecognizer = UITapGestureRecognizer()
        autoFocusGestureRecognizer.addTarget(
            self, action: #selector(autoFocus(_:))
        )

        view.addGestureRecognizer(autoFocusGestureRecognizer)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        videoPreviewLayer?.frame = view.bounds

        captureSessionQueue.async {
            switch self.cameraSetupResult {
            case .success:
                self.captureSession.startRunning()

            case .notAuthorized:
                DispatchQueue.main.async {
                    self.displayPrivacySettingsAlert()
                }

            case .captureSessionConfigurationFailed:
                DispatchQueue.main.async {
                    self.displayCaptureSessionConfigurationFailureAlert()
                }
            }
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        if cameraSetupResult == .success {
            captureSession.stopRunning()
        }

        UIDevice.current.endGeneratingDeviceOrientationNotifications()

        super.viewWillDisappear(animated)
    }

    // MARK: - Orientation Change

    @objc public func deviceOrientationDidChange(_ notification: Notification) {
        guard let device = notification.object as? UIDevice else {
            return
        }

        switch device.orientation {
        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
            lastKnownDeviceOrientation = device.orientation

        default:
            break
        }
    }

    // MARK: - Capture Session

    /// The capture session communication queue.
    private let captureSessionQueue = DispatchQueue(label: "Capture Session Queue")

    /// The capture session.
    private let captureSession = AVCaptureSession()

    /// The capture device
    private var captureDevice: AVCaptureDevice?

    /// The device input matching the required media type.
    private var requiredDeviceInput: AVCaptureDeviceInput?

    /// The captured photo output.
    private let photoOutput: AVCapturePhotoOutput = {
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        return photoOutput
    }()

    /// If the required media type is video,this is the session's preview layer.
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    /// Configure the capture session.
    private func configureCaptureSession() {
        guard cameraSetupResult == .success else {
            return
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        do {
            let device = try makeDevice()
            try addRequiredInput(to: device)
            try addPhotoOutput()

            captureDevice = device
        } catch {
            cameraSetupResult = .captureSessionConfigurationFailed
        }

        captureSession.commitConfiguration()
    }

    /// Make a capture device object for the required media type.
    private func makeDevice() throws -> AVCaptureDevice {
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: requiredMediaType,
            position: .back
        ) else {
            print("Unable to initialize the device.")
            throw CameraSetupResult.captureSessionConfigurationFailed
        }

        return device
    }

    /// Add the device input matching the required media type to the capture
    /// session.
    private func addRequiredInput(to device: AVCaptureDevice) throws {
        let deviceInput = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(deviceInput) else {
            print("Unable to add required input.")
            throw CameraSetupResult.captureSessionConfigurationFailed
        }

        captureSession.addInput(deviceInput)
        requiredDeviceInput = deviceInput

        // NOTE: If multiple orientations are supported, the preview layer's
        // orientation should be set here on the main queue.
    }

    /// Add photo output to the capture session.
    private func addPhotoOutput() throws {
        guard captureSession.canAddOutput(photoOutput) else {
            print("Unable to add photo output.")
            throw CameraSetupResult.captureSessionConfigurationFailed
        }

        captureSession.addOutput(photoOutput)
    }

    private func displayCaptureSessionConfigurationFailureAlert() {
        let privacySettingsAlert = UIAlertController(
            title: "Mimeo",
            message: "Unable to configure the camera.",
            preferredStyle: .alert
        )

        privacySettingsAlert.addAction(UIAlertAction(
            title: "OK",
            style: .cancel,
            handler: nil
        ))

        present(privacySettingsAlert, animated: true, completion: nil)
    }

    // MARK: - Camera Setup

    /// A camera setup result.
    private enum CameraSetupResult: Error {

        /// The camera setup was successful.
        case success

        /// The required media type usage was not authorized.
        case notAuthorized

        /// The capture session configuration failed.
        case captureSessionConfigurationFailed

        /// Does the camera setup result represent a failure?
        var isFailure: Bool {
            switch self {
            case .success:
                return false
            case .notAuthorized, .captureSessionConfigurationFailed:
                return true
            }
        }

    }

    /// The camera setup result.
    private var cameraSetupResult: CameraSetupResult = .success {
        didSet {
            // Allow for errors to propagate through the setup process.
            if oldValue.isFailure && cameraSetupResult == .success {
                cameraSetupResult = oldValue
            }
        }
    }

    // MARK: - Camera Authorization

    /// The required media type.
    private var requiredMediaType: AVMediaType {
        return .video
    }
    /// The authorization status for the required media type.
    public var requiredMediaTypeAuthorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: requiredMediaType)
    }

    /// Check the required media type authorization status and request access if
    /// necessary.
    public func checkAuthorizationStatus() {
        switch requiredMediaTypeAuthorizationStatus {
        case .authorized:
            break

        case .notDetermined:
            captureSessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: requiredMediaType) { granted in
                if !granted {
                    self.cameraSetupResult = .notAuthorized
                }

                self.captureSessionQueue.resume()
            }

        default:
            cameraSetupResult = .notAuthorized
        }
    }

    /// Display an alert which links to the app's settings.
    private func displayPrivacySettingsAlert() {
        let privacySettingsAlert = UIAlertController(
            title: "Mimeo",
            message: "Mimeo doesn't have permission to use the camera, please change privacy settings.",
            preferredStyle: .alert
        )

        privacySettingsAlert.addAction(UIAlertAction(
            title: "OK",
            style: .cancel,
            handler: nil
        ))

        privacySettingsAlert.addAction(UIAlertAction(
            title: "Settings",
            style: .default,
            handler: { _ in
                UIApplication.shared.open(
                    URL(string: UIApplication.openSettingsURLString)!,
                    options: [:],
                    completionHandler: nil
                )
            }
        ))

        present(privacySettingsAlert, animated: true, completion: nil)
    }

    // MARK: - Photo Capture

    public func capturePhoto() {
        captureSessionQueue.async {
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.isHighResolutionPhotoEnabled = true
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    // MARK: - Auto Focus

    private var autoFocusFeedbackLayer: CALayer?

    @objc private func autoFocus(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let gestureRecognizerView = gestureRecognizer.view else {
            return
        }

        guard let captureDevice = captureDevice else {
            return
        }

        guard (try? captureDevice.lockForConfiguration()) != nil else {
            return
        }

        let touchPoint = gestureRecognizer.location(in: gestureRecognizerView)
        let focusPoint = touchPoint.normalized(
            for: gestureRecognizerView.frame.size
        )

        if captureDevice.isFocusPointOfInterestSupported {
            captureDevice.focusPointOfInterest = focusPoint
            captureDevice.focusMode = .continuousAutoFocus
        }

        if captureDevice.isExposurePointOfInterestSupported {
            captureDevice.focusPointOfInterest = focusPoint
            captureDevice.exposureMode = .continuousAutoExposure
        }

        captureDevice.unlockForConfiguration()

        presentAutofocusFeedback(centeredAt: touchPoint)
    }

    private func presentAutofocusFeedback(centeredAt point: CGPoint) {
        self.autoFocusFeedbackLayer?.removeFromSuperlayer()

        var autofocusFeedbackLayer = makeAutofocusFeedbackLayer()

        autofocusFeedbackLayer.removeFromSuperlayer()
        autofocusFeedbackLayer.removeAllAnimations()

        autofocusFeedbackLayer.frame = CGRect(
            x: point.x - autofocusFeedbackLayer.bounds.width / 2,
            y: point.y - autofocusFeedbackLayer.bounds.height / 2,
            width: autofocusFeedbackLayer.bounds.width,
            height: autofocusFeedbackLayer.bounds.width
        )

        addFadeInAnimation(to: &autofocusFeedbackLayer)
        addScaleInAnimation(to: &autofocusFeedbackLayer)
        addFadeOutAnimation(to: &autofocusFeedbackLayer)

        view.layer.addSublayer(autofocusFeedbackLayer)

        self.autoFocusFeedbackLayer = autofocusFeedbackLayer
    }

    private func makeAutofocusFeedbackLayer() -> CALayer {
        let autofocusFeedbackLayer = CALayer()
        autofocusFeedbackLayer.backgroundColor = UIColor.clear.cgColor
        autofocusFeedbackLayer.borderWidth = 1
        autofocusFeedbackLayer.borderColor = UIColor.mimeoYellowDark.cgColor
        autofocusFeedbackLayer.cornerRadius = 16
        autofocusFeedbackLayer.bounds = CGRect(x: 0, y: 0, width: 110, height: 110)
        return autofocusFeedbackLayer
    }

    private func addScaleInAnimation(to layer: inout CALayer) {
        let initialBounds = layer.bounds
        let finalBounds = layer.bounds.scaled(by: 0.75)

        let scaleInAnimation = CABasicAnimation(keyPath: "bounds")
        scaleInAnimation.fromValue = initialBounds
        scaleInAnimation.duration = 0.15

        layer.bounds = finalBounds

        layer.add(scaleInAnimation, forKey: "scaleInAnimation")
    }

    private func addFadeInAnimation(to layer: inout CALayer) {
        let initialOpacity: Float = 0
        let finalOpacity: Float = 1

        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = initialOpacity
        fadeInAnimation.duration = 0.1

        layer.opacity = finalOpacity

        layer.add(fadeInAnimation, forKey: "fadeInAnimation")
    }

    private func addFadeOutAnimation(to layer: inout CALayer) {
        let fadeOutAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeOutAnimation.keyTimes = [0, NSNumber(value: (1.3 - 0.25) / 1.3), 1]
        fadeOutAnimation.values = [1, 1, 0]
        fadeOutAnimation.duration = 1.3

        layer.opacity = 0

        layer.add(fadeOutAnimation, forKey: "fadeOutAnimation")
    }

}

// MARK: - Photo Capture Delegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {

    public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil else { return }
        delegate?.cameraViewController(self, didCapturePhoto: photo)
    }

}
