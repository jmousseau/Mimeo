//
//  UIColor.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/8/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

extension UIColor {

    /// Mimeo yellow for light backgrounds.
    public static var mimeoYellowLight: UIColor {
        UIColor(red: 185 / 255, green: 145 / 255, blue: 0, alpha: 1)
    }

    /// Mimeo yellow for dark backgrounds.
    public static var mimeoYellowDark: UIColor {
        .systemYellow
    }

    /// Mimeo yellow that adapts to the current user interface style.
    public static var mimeoYellow: UIColor {
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .mimeoYellowDark
            } else {
                return .mimeoYellowLight
            }
        }
    }

}

