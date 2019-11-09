//
//  Settings.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/19/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

/// The Quick Recognition setting.
public enum QuickRecognitionSetting: String, CaseIterable, BooleanPreferenceStorable {

    /// The Quick Recognition preference key.
    public static let preferenceKey = "quick-recognition"

    /// The default Quick Recognition preference value.
    public static let defaultPreferenceValue: QuickRecognitionSetting = .off

    /// The Quick Recognition case that is considered enabled.
    public static let enabledCase: QuickRecognitionSetting = .on

    /// The Quick Recognition case that is considered disabled.
    public static var disabledCase: QuickRecognitionSetting = .off

    /// Quick Recognition is on.
    case on = "on"

    /// Quick Recognition is off.
    case off = "off"

}
