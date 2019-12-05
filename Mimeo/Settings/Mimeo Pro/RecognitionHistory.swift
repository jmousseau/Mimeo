//
//  RecognitionHistory.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

/// The recognition history setting.
public enum RecognitionHistory: String, CaseIterable, BooleanPreferenceStorable {

    /// The recognition history preference key.
    public static var preferenceKey: String = "recognition-history"

    /// The default recognition history preference.
    public static var defaultPreference: RecognitionHistory = .off

    /// The recognition history case that is considered enabled.
    public static var enabledCase: RecognitionHistory = .on

    /// The recognition history case that is consiered disabled.
    public static var disabledCase: RecognitionHistory = .off

    /// Recognition history is on.
    case on = "on"

    /// Recognition history is on.
    case off = "off"

}
