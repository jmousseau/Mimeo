//
//  AutocropPreference.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/12/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

/// The autocrop preference.
public enum AutocropPreference: String, BooleanPreferenceStorable {

    /// The autocrop preference key.
    public static var preferenceKey: String = "autocrop"

    /// The default autocrop preference.
    public static var defaultPreference: AutocropPreference = .off

    /// The enabled autocrop preference case.
    public static var enabledCase: AutocropPreference = .on

    /// The disabled autocrop preference case.
    public static var disabledCase: AutocropPreference = .off

    /// Autocrop is on.
    case on = "on"

    /// Autocrop is off.
    case off = "off"

}
