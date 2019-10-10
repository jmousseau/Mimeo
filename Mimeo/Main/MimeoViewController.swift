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

    private lazy var cancelImage: UIImage? = {
        let configuration = UIImage.SymbolConfiguration(weight: .regular)
        return UIImage(systemName: "multiply", withConfiguration: configuration)
    }()

    private lazy var cameraShutterButton: CameraShutterButton = {
        let button = CameraShutterButton()
        button.addTarget(self, action: #selector(recognizeText), for: .touchUpInside)
        return button
    }()

    private lazy var resultsViewController = ResultsViewController()

    private var recognizeTextRequest: VNRecognizeTextRequest?

    public init() {
        super.init(nibName: nil, bundle: nil)

        textRecognizer.delegate = self
        cameraViewController.delegate = self

        addCameraViewController()
        addShutterButton()
        addResultsViewController()

        view.bringSubviewToFront(cameraShutterButton)
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

    private func addShutterButton() {
        view.addSubview(cameraShutterButton)

        cameraShutterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraShutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: cameraShutterButton.bottomAnchor, constant: 20.0),
            cameraShutterButton.widthAnchor.constraint(equalToConstant: 70),
            cameraShutterButton.heightAnchor.constraint(equalToConstant: 70)
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
