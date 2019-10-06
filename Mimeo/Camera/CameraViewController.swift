//
//  CameraViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 9/29/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import AVFoundation
import UIKit

/// The camera view controller delegate.
public protocol CameraViewControllerDelegate {

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
    public var delegate: CameraViewControllerDelegate?

    // MARK: - View Controller Lifecycle`

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
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

        super.viewWillDisappear(animated)
    }

    // MARK: - Capture Session

    /// The capture session communication queue.
    private let captureSessionQueue = DispatchQueue(label: "Capture Session Queue")

    /// The capture session.
    private let captureSession = AVCaptureSession()

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
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

// MARK: - Photo Capture Delegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {

    public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        // TODO: Some how get the data back to CameraView component. Delegate
        // pattern did not work because in order for the delegate to be weak it
        // must be a class. However, SwiftUI views are structs.
    }

}
