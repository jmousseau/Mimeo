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

    private var cameraViewController = CameraViewController()

    public init() {
        super.init(nibName: nil, bundle: nil)

        addCameraViewController()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addCameraViewController() {
        cameraViewController.delegate = self

        addChild(cameraViewController)
        view.addSubview(cameraViewController.view)
        cameraViewController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            cameraViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            cameraViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            cameraViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            cameraViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

}

// MARK: - Camera View Controller Delegate

extension MimeoViewController: CameraViewControllerDelegate {

    public func cameraViewController(
        _ cameraViewController: CameraViewController,
        didCapturePhoto photo: AVCapturePhoto
    ) {
        // TODO: Run text recognition on the captured image and display the text
        // on a guassian blur view.
    }

}
