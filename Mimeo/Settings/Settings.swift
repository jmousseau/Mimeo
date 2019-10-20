//
//  Settings.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/19/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

/// The Quick Recognition setting.
public enum QuickRecognitionSetting: String, CaseIterable, PreferenceStorable {

    /// The Quick Recognition preference key.
    public static let preferenceKey = "quick-recognition"

    /// The default Quick Recognition preference value.
    public static let defaultPreferenceValue = Self.off.rawValue

    /// Quick Recognition is on.
    case on = "on"

    /// Quick Recognition is off.
    case off = "off"

}
