//
//  UIDevice.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit
import AVFoundation

extension UIDeviceOrientation {

    /// The device orientation's corresponding video orientation.
    public var videoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portraitUpsideDown:
            return .portraitUpsideDown

        case .landscapeLeft:
            return .landscapeRight

        case .landscapeRight:
            return .landscapeLeft

        default:
            return .portrait
        }
    }

}
