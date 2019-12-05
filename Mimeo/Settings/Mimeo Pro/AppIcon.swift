//
//  AppIcon.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

/// An app icon.
public enum AppIcon: String, PreferenceStorable, CaseIterable {

    /// The app icon preference key.
    public static var preferenceKey: String = "app-icon"

    /// The default app icon preference.
    public static var defaultPreference: AppIcon = .light

    /// NOTE: The case order determines the presentation order.

    /// The light app icon.
    case light = "light"

    /// The dark app icon.
    case dark = "dark"

    /// The app icon's name.
    public var name: String {
        switch self {
        case .light:
            return "Light"

        case .dark:
            return "Dark"
        }
    }

    /// The app icon's asset name.
    public var assetName: String? {
        switch self {
        case .light:
            return nil

        case .dark:
            return "iPhone App Dark"
        }
    }

}
