//
//  MimeoViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import AVFoundation
import Iris
import MimeoKit
import UIKit
import Vision

public let CameraOverlayVerticalOffset: CGFloat = -25

public final class MimeoViewController: UIViewController {

    private let preferencesStore = PreferencesStore.default()

    private var appIconFetchedResultsController: AnyFetchedResultController?

    private lazy var textRecognizer: TextRecognizer = {
        do {
            return try TextRecognizer(fontClassifierModel: FontClassifierV1().model)
        } catch {
            return TextRecognizer()
        }
    }()

    private let cameraViewController = CameraViewController()

    private let settingsViewController = SettingsViewController()

    private lazy var settingsNavigationViewController: UINavigationController = {
        let settingsNavigationViewController = UINavigationController(
            rootViewController: settingsViewController
        )
        settingsNavigationViewController.navigationBar.prefersLargeTitles = true
        return settingsNavigationViewController
    }()

    private lazy var imagePickerViewController: UIImagePickerController = {
        let imagePickerViewController = UIImagePickerController()
        imagePickerViewController.delegate = self
        imagePickerViewController.view.tintColor = .mimeoYellow
        return imagePickerViewController
    }()

    private lazy var cameraOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var cancelImage: UIImage? = {
        let configuration = UIImage.SymbolConfiguration(weight: .regular)
        return UIImage(systemName: "multiply", withConfiguration: configuration)
    }()

    private lazy var cameraShutterButton: CameraShutterButton = {
        let button = CameraShutterButton()
        button.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        return button
    }()

    private lazy var buttonsStackView: UIStackView = {
        let buttonsStackView = UIStackView()
        buttonsStackView.distribution = .equalSpacing
        buttonsStackView.addArrangedSubview(settingsButton)
        buttonsStackView.addArrangedSubview(recognitionHistoryButton)
        buttonsStackView.addArrangedSubview(importButton)
        return buttonsStackView
    }()

    private lazy var settingsImage: UIImage? = {
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        return UIImage(
            systemName: "gear",
            withConfiguration: configuration
        )
    }()

    private lazy var settingsButton: UIButton = {
        let settingsButton = UIButton()
        settingsButton.tintColor = .mimeoYellowDark
        settingsButton.setImage(settingsImage, for: .normal)
        settingsButton.addTarget(
            self, action:
            #selector(presentSettings),
            for: .touchUpInside
        )
        return settingsButton
    }()

    private lazy var recognitionHistoryImage: UIImage? = {
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        return UIImage(
            systemName: "book",
            withConfiguration: configuration
        )
    }()

    private lazy var recognitionHistoryButton: UIButton = {
        let recognitionHistoryButton = UIButton()
        recognitionHistoryButton.tintColor = .mimeoYellow
        recognitionHistoryButton.setImage(recognitionHistoryImage, for: .normal)
        recognitionHistoryButton.addTarget(self, action: #selector(presentRecognitionHistory), for: .touchUpInside)
        return recognitionHistoryButton
    }()

    private lazy var importImage: UIImage? = {
        let configuration = UIImage.SymbolConfiguration(scale: .large)
        return UIImage(
            systemName: "square.and.arrow.down",
            withConfiguration: configuration
        )
    }()

    private lazy var importButton: UIButton = {
        let importButton = UIButton()
        importButton.tintColor = .mimeoYellowDark
        importButton.setImage(importImage, for: .normal)
        importButton.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        return importButton
    }()

    private lazy var resultsViewController: ResultsViewController = {
        return ResultsViewController(cameraShutterView: cameraShutterButton)
    }()

    private var imageRequests = [VNImageBasedRequest]()

    public init() {
        super.init(nibName: nil, bundle: nil)

        cameraViewController.delegate = self

        addCameraViewController()
        addCameraOverlayView()

        addButtonsStackView()
        addShutterButton()
        addResultsViewController()

        appIconFetchedResultsController = preferencesStore.fetchedResultController(
            for: AppIcon.self,
            didChange: {
                UIApplication.shared.appIcon = self.preferencesStore.get(AppIcon.self)
            }
        )

        view.bringSubviewToFront(cameraShutterButton)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // When the app is installed for the first time and CloudKit is synced,
        // the fetched results controller will not call `didChange`. For most
        // preferences, that is OK because the correct preference value will be
        // shown in the UI for subsequent sessions. In the case of the App Icon,
        // we always need to ensure the current app icon is correct on launch.
        UIApplication.shared.appIcon = preferencesStore.get(AppIcon.self)
    }

}

// MARK: - View Layout

extension MimeoViewController {

    private func addCameraViewController() {
        addChild(cameraViewController)
        view.addSubview(cameraViewController.view)
        cameraViewController.didMove(toParent: self)

        cameraViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            cameraViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            cameraViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            cameraViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addCameraOverlayView() {
        view.addSubview(cameraOverlayView)

        cameraOverlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraOverlayView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            cameraOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraOverlayView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            NSLayoutConstraint(
                item: cameraOverlayView,
                attribute: .height,
                relatedBy: .equal,
                toItem: cameraOverlayView,
                attribute: .width,
                multiplier: 4 / 3,
                constant: 0
            )
        ])
    }

    private func addShutterButton() {
        let topLayoutGuide = UILayoutGuide()
        let bottomLayoutGuide = UILayoutGuide()

        cameraShutterButton.addLayoutGuide(topLayoutGuide)
        cameraShutterButton.addLayoutGuide(bottomLayoutGuide)

        view.addSubview(cameraShutterButton)

        cameraShutterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topLayoutGuide.heightAnchor.constraint(equalTo: bottomLayoutGuide.heightAnchor, multiplier: 0.5),
            topLayoutGuide.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor),
            topLayoutGuide.bottomAnchor.constraint(equalTo: cameraShutterButton.topAnchor),
            bottomLayoutGuide.topAnchor.constraint(equalTo: cameraShutterButton.bottomAnchor),
            bottomLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cameraShutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraShutterButton.heightAnchor.constraint(equalToConstant: 70),
            cameraShutterButton.widthAnchor.constraint(equalToConstant: 70)
        ])
    }

    private func addButtonsStackView() {
        view.addSubview(buttonsStackView)

        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonsStackView.topAnchor.constraint(
                equalTo: cameraOverlayView.bottomAnchor,
                constant: 20
            ),
            buttonsStackView.leadingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.leadingAnchor,
                constant: 20
            ),
            buttonsStackView.trailingAnchor.constraint(
                equalTo: view.layoutMarginsGuide.trailingAnchor,
                constant: -20
            )
        ])
    }

    private func addResultsViewController() {
        addChild(resultsViewController)
        view.addSubview(resultsViewController.view)
        resultsViewController.didMove(toParent: self)

        resultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultsViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            resultsViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            resultsViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            resultsViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        resultsViewController.recognitionState = .notStarted
    }

}

// MARK: - Camera View Controller

extension MimeoViewController: CameraViewControllerDelegate {

    @objc private func capturePhoto() {
        cameraViewController.capturePhoto()
    }

    @objc private func cancelRecognizeTextRequest() {
        imageRequests.forEach({ imageRequest in
            imageRequest.cancel()
        })
        imageRequests = []
        cameraShutterButton.image = nil
        cameraShutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        resultsViewController.recognitionState = .notStarted
    }

    public var recognitionState: TextRecognizer.RecognitionState {
        resultsViewController.recognitionState
    }

    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didCapturePhoto photo: AVCapturePhoto
    ) {
        recognizeText(in: photo)
    }

    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didAutoCropImage image: UIImage
    ) {
        recognizeText(in: image)
    }

}

// MARK: - Settings

extension MimeoViewController {

    @objc private func presentSettings() {
        present(settingsNavigationViewController, animated: true, completion: nil)
    }

    @objc private func dismissSettings() {
        settingsNavigationViewController.dismiss(animated: true, completion: nil)
    }

}

// MARK: - Recognition History

extension MimeoViewController {

    @objc private func presentRecognitionHistory() {
        let recognitionHistoryNavigationViewController = UINavigationController(
            rootViewController: RecognitionHistoryViewController()
        )
        recognitionHistoryNavigationViewController.navigationBar.prefersLargeTitles = true
        present(recognitionHistoryNavigationViewController, animated: true)
    }

}

// MARK: - Image Picker

extension MimeoViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @objc private func pickImage() {
        let imagePickerViewController = UIImagePickerController()
        imagePickerViewController.delegate = self
        imagePickerViewController.view.tintColor = .mimeoYellow
        present(imagePickerViewController, animated: true)
    }

    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }

        guard let image = (info[.originalImage] as? UIImage)?.orientedUp() else {
            return
        }

        if preferencesStore.get(AutocropPreference.self).isEnabled {
            ImageCropper.cropToLargestRectangle(
                in: image
            ) { autocroppedImage in
                DispatchQueue.main.async {
                    guard let autocroppedImage = autocroppedImage else {
                        self.recognizeText(in: image)
                        return
                    }

                    self.recognizeText(in: autocroppedImage)
                }
            }
        } else {
            recognizeText(in: image)
        }
    }

}

// MARK: - Text Recognition

extension MimeoViewController {

    private func recognizeText(in photo: AVCapturePhoto) {
        guard let image = photo.cgImageRepresentation(),
            let orientationRawValue = photo.metadata[kCGImagePropertyOrientation as String] as? UInt32,
            let orientation = CGImagePropertyOrientation(rawValue: orientationRawValue) else {
            return
        }

        recognizeText(in: image.takeUnretainedValue(), withOrientation: orientation)
    }

    private func recognizeText(in image: UIImage) {
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let image = image.cgImage else {
            return
        }

        recognizeText(in: image, withOrientation: orientation)
    }

    private func recognizeText(
        in image: CGImage,
        withOrientation orientation: CGImagePropertyOrientation
    ) {
        let uiImage = UIImage(cgImage: image, scale: 1, orientation: orientation.imageOrientation)

        imageRequests = textRecognizer.recognizeText(
            in: uiImage.orientedUp()!.cgImage!,
            orientation: .up,
            recognitionLevel: preferencesStore.get(QuickRecognitionSetting.self).recognitionLevel,
            completion: { recognitionState in
                DispatchQueue.main.async {
                    self.didUpdate(recognitionState: recognitionState)
                }
            }
        )
    }

    fileprivate func didUpdate(
        recognitionState: TextRecognizer.RecognitionState
    ) {
        switch recognitionState {
        case .notStarted:
            cameraShutterButton.image = nil
            cameraShutterButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)

        case .inProgress, .complete, .failed:
            cameraShutterButton.image = cancelImage
            cameraShutterButton.removeTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
            cameraShutterButton.addTarget(self, action: #selector(cancelRecognizeTextRequest), for: .touchUpInside)
        }

        resultsViewController.recognitionState = recognitionState
    }

}
