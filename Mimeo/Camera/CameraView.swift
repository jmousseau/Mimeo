//
//  CameraView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 9/29/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import SwiftUI

public struct CameraView: View {

    private let cameraViewController = CameraViewController()

    public var body: some View {
        cameraViewController
    }

    public func capturePhoto() {
        cameraViewController.capturePhoto()
    }

}
