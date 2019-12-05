//
//  UIApplication.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

extension UIApplication {

    /// The application's app icon.
    ///
    /// Setting the app icon to the same icon will have no effect.
    public var appIcon: AppIcon {
        get {
            AppIcon(assetName: alternateIconName)
        }

        set {
            if (appIcon != newValue) {
                setAlternateIconName(newValue.assetName)
            }
        }
    }

}
