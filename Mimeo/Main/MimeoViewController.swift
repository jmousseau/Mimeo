//
//  MimeoViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import AVFoundation
import UIKit

public final class MimeoViewController: UIViewController {

    private let textRecognizer = TextRecognizer()

    private lazy var cameraViewController: CameraViewController = {
        let cameraViewController = CameraViewController()
        cameraViewController.view.translatesAutoresizingMaskIntoConstraints = false
        return cameraViewController
    }()

    private lazy var cameraShutterButton: CameraShutterButton = {
        let button = CameraShutterButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(detectText), for: .touchUpInside)
        return button
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)

        textRecognizer.delegate = self
        cameraViewController.delegate = self

        addCameraViewController()
        addShutterButton()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addCameraViewController() {
        addChild(cameraViewController)
        view.addSubview(cameraViewController.view)
        cameraViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            cameraViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            cameraViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            cameraViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            cameraViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func addShutterButton() {
        view.addSubview(cameraShutterButton)

        NSLayoutConstraint.activate([
            cameraShutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: cameraShutterButton.bottomAnchor, constant: 20.0),
            cameraShutterButton.widthAnchor.constraint(equalToConstant: 70),
            cameraShutterButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }

    @objc func detectText() {
        cameraViewController.capturePhoto()
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

        cameraShutterButton.isEnabled = false

        try! textRecognizer.recognizeText(
            in: image.takeUnretainedValue(),
            orientation: orientation
        )
    }

}

// MARK: - Text Recognizer Delegate

extension MimeoViewController: TextRecognizerDelegate {

    public func textRecognizer(
        _ textRecognizer: TextRecognizer,
        didRecognizeText recognizedText: String
    ) {
        cameraShutterButton.isEnabled = true

        print(recognizedText)
    }

}
