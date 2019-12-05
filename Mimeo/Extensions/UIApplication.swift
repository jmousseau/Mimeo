//
//  UIApplication.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

extension UIApplication {

    /// Set the application's app icon.
    /// - Parameter appIcon: The desired application app icon.
    public func set(appIcon: AppIcon) {
        setAlternateIconName(appIcon.assetName)
    }

}
