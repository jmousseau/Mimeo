//
//  CameraViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 9/29/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import AVFoundation
import Iris
import MimeoKit
import UIKit
import Vision

/// The camera view controller delegate.
public protocol CameraViewControllerDelegate: class {

    /// The camer view controller delegate's recognition state.
    var recognitionState: TextRecognizer.RecognitionState { get }

    /// The camera view controller captured a photo.
    /// - Parameter cameraViewController: The camera view controller which
    /// captured the `photo`.
    /// - Parameter photo: The captured photo.
    func cameraViewController(
        _ cameraViewController: CameraViewController,
        didCapturePhoto photo: AVCapturePhoto
    )

    /// The camera view controller auto cropped an image.
    /// - Parameters:
    ///   - cameraViewController: The camer view controller which auto cropped
    ///     the `image`.
    ///   - image: The auto cropped image.
    func cameraViewController(
        _ cameraViewController: CameraViewController,
        didAutoCropImage image: UIImage
    )

}

/// A camera view controller.
public final class CameraViewController: UIViewController {

    /// The default preference's store.
    private let preferencesStore = PreferencesStore.default()

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

        autocropController = preferencesStore.fetchedResultController(
            for: AutocropPreference.self,
            didChange: {
                self.isAutocropEnabled = self.preferencesStore.get(
                    AutocropPreference.self
                ).isEnabled
            }
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )

        addVideoPreview()
        addAutocropButton()
        addInstructionsView()

        // Update to default instructions label state.
        updateInstructionsLabel(animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        isAutocropEnabled = preferencesStore.get(AutocropPreference.self).isEnabled

        if requiredMediaType == .video {
            videoPreviewLayer = AVCaptureVideoPreviewLayer()
        }

        if let videoPreviewLayer = videoPreviewLayer {
            videoPreviewLayer.session = captureSession
            videoPreviewView.layer.addSublayer(videoPreviewLayer)
        }

        checkAuthorizationStatus()
        captureSessionQueue.async {
            self.configureCaptureSession()
        }

        let autoFocusGestureRecognizer = UITapGestureRecognizer()
        autoFocusGestureRecognizer.addTarget(
            self, action: #selector(autoFocus(_:))
        )

        videoPreviewView.addGestureRecognizer(autoFocusGestureRecognizer)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        videoPreviewLayer?.frame = videoPreviewView.bounds
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

    /// The sample buffer queue.
    private let sampleBufferQueue = DispatchQueue(label: "Sample Buffer Queue")

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

    /// The video output used for the autocrop overlay.
    private lazy var videoOutput: AVCaptureVideoDataOutput = {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        return videoOutput
    }()

    /// The video preview view.
    private let videoPreviewView = UIView(frame: .zero)

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
            try addVideoOutput()

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

    /// Add video output to the capture session.
    private func addVideoOutput() throws {
        guard captureSession.canAddOutput(videoOutput) else {
            print("Unable to add video output.")
            throw CameraSetupResult.captureSessionConfigurationFailed
        }

        captureSession.addOutput(videoOutput)
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

    private func addVideoPreview() {
        view.addSubview(videoPreviewView)

        videoPreviewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoPreviewView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            videoPreviewView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoPreviewView.rightAnchor.constraint(equalTo: view.rightAnchor),
            videoPreviewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            videoPreviewView.heightAnchor.constraint(
                equalTo: view.widthAnchor,
                multiplier: 4.0 / 3.0
            )
        ])
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

    // MARK: - Autofocus

    private var autofocusFeedbackLayer: CALayer?

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
        self.autofocusFeedbackLayer?.removeFromSuperlayer()

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

        videoPreviewLayer?.addSublayer(autofocusFeedbackLayer)

        self.autofocusFeedbackLayer = autofocusFeedbackLayer
    }

    private func makeAutofocusFeedbackLayer() -> CALayer {
        let autofocusFeedbackLayer = CALayer()
        autofocusFeedbackLayer.backgroundColor = UIColor.clear.cgColor
        autofocusFeedbackLayer.borderWidth = 2
        autofocusFeedbackLayer.borderColor = UIColor.mimeoYellowDark.cgColor
        autofocusFeedbackLayer.cornerRadius = 16
        autofocusFeedbackLayer.bounds = CGRect(x: 0, y: 0, width: 80, height: 80)
        return autofocusFeedbackLayer
    }

    private func addScaleInAnimation(to layer: inout CALayer) {
        let initialBounds = layer.bounds.scaled(by: 1.25)
        let finalBounds = layer.bounds

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

    // MARK: - Instructions

    private var framesWithText = [Double](repeating: 0, count: 60)

    private var textExistsInVideoPreview: Bool = false {
        didSet {
            if oldValue != textExistsInVideoPreview {
                DispatchQueue.main.async {
                    self.updateInstructionsLabel(animated: true)
                }
            }
        }
    }

    private lazy var instructionsLabel: UILabel = {
        let instructionsLabel = UILabel()
        instructionsLabel.numberOfLines = 0
        instructionsLabel.text = "Photograph printed text"
        instructionsLabel.textAlignment = .center
        instructionsLabel.textColor = .white
        return instructionsLabel
    }()

    private lazy var instructionsView: UIView = {
        let instructionsView = UIView()
        instructionsView.backgroundColor = .black
        instructionsView.layer.cornerRadius = 8
        return instructionsView
    }()

    private func addInstructionsView() {
        instructionsView.addSubview(instructionsLabel)

        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionsLabel.leadingAnchor.constraint(
                equalTo: instructionsView.leadingAnchor,
                constant: 8
            ),
            instructionsLabel.topAnchor.constraint(
                equalTo: instructionsView.topAnchor,
                constant: 8
            ),
            instructionsLabel.trailingAnchor.constraint(
                equalTo: instructionsView.trailingAnchor,
                constant: -8
            ),
            instructionsLabel.bottomAnchor.constraint(
                equalTo: instructionsView.bottomAnchor,
                constant: -8
            ),
        ])

        videoPreviewView.addSubview(instructionsView)

        instructionsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            instructionsView.leadingAnchor.constraint(
                greaterThanOrEqualTo: videoPreviewView.layoutMarginsGuide.leadingAnchor
            ),
            instructionsView.topAnchor.constraint(
                equalTo: videoPreviewView.safeAreaLayoutGuide.topAnchor,
                constant: 8
            ),
            instructionsView.trailingAnchor.constraint(
                lessThanOrEqualTo: videoPreviewView.layoutMarginsGuide.trailingAnchor
            ),
            instructionsView.centerXAnchor.constraint(
                equalTo: videoPreviewView.centerXAnchor
            )
        ].compactMap({ $0 }))
    }

    private func updateInstructionsLabel(animated: Bool) {
        let update: () -> Void = {
            self.instructionsView.alpha = self.textExistsInVideoPreview ? 0 : 1
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: update)
        } else {
            update()
        }
    }

    // MARK: - Autocrop

    private let autocropRectangleDetectionDispatchGroup = DispatchGroup()

    private var autocropController: AnyFetchedResultController?

    private lazy var autocropImage: UIImage? = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        return UIImage(
            systemName: "crop",
            withConfiguration: configuration
        )
    }()

    private var autocropButtonTitle: String {
        isAutocropEnabled ? "ON" : "OFF"
    }

    private var isAutocropEnabled: Bool = false {
        didSet {
            autocropButton.setTitle(autocropButtonTitle, for: .normal)
            autocropButton.backgroundColor = isAutocropEnabled ? .mimeoYellowDark : .clear
            autocropButton.tintColor = isAutocropEnabled ? .black : .white
            autocropButton.setTitleColor(isAutocropEnabled ? .black : .white, for: .normal)
        }
    }

    private lazy var autocropButton: UIButton = {
        let autocropButton = UIButton()
        autocropButton.setImage(autocropImage, for: .normal)
        autocropButton.setTitle(autocropButtonTitle, for: .normal)
        autocropButton.titleLabel?.font = .monospacedSystemFont(ofSize: 15, weight: .semibold)
        autocropButton.setContentEdgeInsets(
            UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 8),
            withTitlePadding: 4
        )
        autocropButton.layer.cornerRadius = 8
        autocropButton.addTarget(self, action: #selector(toggleAutocropFeature), for: .touchUpInside)
        return autocropButton
    }()

    private var numberOfConsecutiveFramesWithoutRectangle = 0

    private var shouldRemoveAutocropOverlay: Bool {
        numberOfConsecutiveFramesWithoutRectangle >= 3
    }

    private let autocropOverlay: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.mimeoYellowDark.cgColor
        layer.lineWidth = 2
        layer.opacity = 1
        layer.fillColor = UIColor.mimeoYellowDark.withAlphaComponent(0.18).cgColor
        return layer
    }()

    private func addAutocropButton() {
        view.addSubview(autocropButton)

        autocropButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            autocropButton.trailingAnchor.constraint(equalTo: videoPreviewView.trailingAnchor, constant: -8),
            autocropButton.bottomAnchor.constraint(equalTo: videoPreviewView.bottomAnchor, constant: -8)
        ])
    }

    @objc private func toggleAutocropFeature() {
        var autocropPreference = preferencesStore.get(AutocropPreference.self)
        autocropPreference.toggle()
        preferencesStore.set(autocropPreference)
    }

    private func autocropLayerRequest() -> VNImageBasedRequest? {
        guard isAutocropEnabled,
            (delegate?.recognitionState ?? .notStarted) == .notStarted else {
            self.removeAutocropOverlay()
            return nil
        }

        autocropRectangleDetectionDispatchGroup.enter()

        return RectangleDetector.detectRectanglesRequest() { quadrilaterals in
            DispatchQueue.main.async {
                defer {
                    self.autocropRectangleDetectionDispatchGroup.leave()
                }

                guard let quadrilateral = quadrilaterals.sorted(by: { lhs, rhs in
                    lhs.area > rhs.area
                }).first else {
                    self.numberOfConsecutiveFramesWithoutRectangle += 1

                    if self.shouldRemoveAutocropOverlay {
                        self.removeAutocropOverlay()
                    }

                    return
                }

                self.numberOfConsecutiveFramesWithoutRectangle = 0

                guard let videoPreviewLayer = self.videoPreviewLayer else {
                    return
                }

                if self.autocropOverlay.superlayer == nil {
                    videoPreviewLayer.addSublayer(self.autocropOverlay)
                }


                /// The image overlay requires an up orientation.
                self.autocropOverlay.path = quadrilateral
                    .rotatedFromRightToUp()
                    .denormalizeInCoordinateSpace(of: videoPreviewLayer)
                    .path.cgPath
            }
        }
    }

    private func removeAutocropOverlay() {
        autocropRectangleDetectionDispatchGroup.notify(queue: .main) {
            self.autocropOverlay.removeFromSuperlayer()
            self.numberOfConsecutiveFramesWithoutRectangle = 0
        }
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

        guard isAutocropEnabled,
            let image = photo.cgImageRepresentation()?.takeUnretainedValue(),
            let orientationRawValue = photo.metadata[kCGImagePropertyOrientation as String] as? UInt32,
            let orientation = CGImagePropertyOrientation(rawValue: orientationRawValue) else {
            delegate?.cameraViewController(self, didCapturePhoto: photo)
            return
        }

        ImageCropper.cropToLargestRectangle(
            in: UIImage(
                cgImage: image,
                scale: 1,
                orientation: orientation.imageOrientation
            ).orientedUp()!
        ) { autocroppedImage in
            guard let autocroppedImage = autocroppedImage else {
                self.delegate?.cameraViewController(self, didCapturePhoto: photo)
                return
            }

            self.delegate?.cameraViewController(self, didAutoCropImage: autocroppedImage)
        }
    }

}

// MARK: - Sample Buffer Delegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        var imageRequests = [VNImageBasedRequest]()

        if let rectangleDetectionRequest = autocropLayerRequest() {
            imageRequests.append(rectangleDetectionRequest)
        }

        imageRequests.append(TextDetector
            .textExistsRequest() { textExistsInVideoPreview in
            if self.framesWithText.count > 0 {
                self.framesWithText.removeFirst()
            }
            self.framesWithText.append(textExistsInVideoPreview ? 1 : 0)
            self.textExistsInVideoPreview =
                self.framesWithText.reduce(.zero, +) / Double(self.framesWithText.count) > 0.5
        })

        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .right
            ).perform(imageRequests)
        }
    }

}
