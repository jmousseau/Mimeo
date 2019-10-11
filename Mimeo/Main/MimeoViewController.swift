//
//  MimeoViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

public final class MimeoViewController: UIViewController {

    private let textRecognizer = TextRecognizer()

    private let cameraViewController = CameraViewController()

    private lazy var instructionsLabel: UILabel = {
        let instructionsLabel = UILabel()
        instructionsLabel.numberOfLines = 0
        instructionsLabel.text = "Take a photo of printed text."
        instructionsLabel.textAlignment = .center
        return instructionsLabel
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

    private lazy var cameraShutterButtonStackView: UIStackView = {
        let cameraShutterButtonStackView = UIStackView()
        cameraShutterButtonStackView.axis = .vertical
        cameraShutterButtonStackView.distribution = .equalCentering
        cameraShutterButtonStackView.addArrangedSubview(UIView())
        cameraShutterButtonStackView.addArrangedSubview(cameraShutterButton)
        cameraShutterButtonStackView.addArrangedSubview(UIView())
        return cameraShutterButtonStackView
    }()

    private lazy var cameraShutterButton: CameraShutterButton = {
        let button = CameraShutterButton()
        button.addTarget(self, action: #selector(recognizeText), for: .touchUpInside)
        return button
    }()

    private lazy var resultsViewController: ResultsViewController = {
        return ResultsViewController(cameraShutterView: cameraShutterButton)
    }()

    private var recognizeTextRequest: VNRecognizeTextRequest?

    public init() {
        super.init(nibName: nil, bundle: nil)

        textRecognizer.delegate = self
        cameraViewController.delegate = self

        addCameraViewController()
        addCameraOverlayView()

        addInstructionsLabel()
        addShutterButton()
        addResultsViewController()

        view.bringSubviewToFront(cameraShutterButtonStackView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
            cameraOverlayView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            cameraOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraOverlayView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            cameraOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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

    private func addInstructionsLabel() {
        view.addSubview(instructionsLabel)

        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionsLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            instructionsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            instructionsLabel.bottomAnchor.constraint(equalTo: cameraOverlayView.topAnchor)
        ])
    }

    private func addShutterButton() {
        view.addSubview(cameraShutterButtonStackView)

        cameraShutterButton.translatesAutoresizingMaskIntoConstraints = false
        cameraShutterButtonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraShutterButtonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraShutterButtonStackView.topAnchor.constraint(equalTo: cameraOverlayView.bottomAnchor),
            cameraShutterButtonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cameraShutterButton.heightAnchor.constraint(equalToConstant: 70),
            cameraShutterButton.widthAnchor.constraint(equalToConstant: 70)
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

    @objc func recognizeText() {
        cameraViewController.capturePhoto()
    }

    @objc func cancelRecognizeTextRequest() {
        recognizeTextRequest?.cancel()
        cameraShutterButton.image = nil
        cameraShutterButton.addTarget(self, action: #selector(recognizeText), for: .touchUpInside)
        resultsViewController.recognitionState = .notStarted
    }
}

// MARK: - Camera View Controller Delegate

extension MimeoViewController: CameraViewControllerDelegate {

    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didCapturePhoto photo: AVCapturePhoto
    ) {
        guard let image = photo.cgImageRepresentation(),
            let orientationRawValue = photo.metadata[kCGImagePropertyOrientation as String] as? UInt32,
            let orientation = CGImagePropertyOrientation(rawValue: orientationRawValue) else {
            return
        }

        cameraShutterButton.image = cancelImage

        recognizeTextRequest = try! textRecognizer.recognizeText(
            in: image.takeUnretainedValue(),
            orientation: orientation
        )
    }

}

// MARK: - Text Recognizer Delegate

extension MimeoViewController: TextRecognizerDelegate {

    public func textRecognizer(
        _ textRecognizer: TextRecognizer,
        didUpdateRecognitionState recognitionState: TextRecognizer.RecognitionState
    ) {
        switch recognitionState {
        case .notStarted:
            cameraShutterButton.image = nil
            cameraShutterButton.addTarget(self, action: #selector(recognizeText), for: .touchUpInside)

        case .inProgress, .complete:
            cameraShutterButton.image = cancelImage
            cameraShutterButton.removeTarget(self, action: #selector(recognizeText), for: .touchUpInside)
            cameraShutterButton.addTarget(self, action: #selector(cancelRecognizeTextRequest), for: .touchUpInside)
        }

        resultsViewController.recognitionState = recognitionState
    }

}
