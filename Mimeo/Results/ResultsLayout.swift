//
//  ResultsLayout.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/10/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

/// A results layout.
public enum ResultsLayout: String, CaseIterable, PreferenceStorable {

    /// The results layout preference key.
    public static let preferenceKey = "resultsLayout"

    /// The default results layout preference value.
    public static let defaultPreferenceValue = Self.plain.rawValue

    /// The plain layout. All recognized text is sorted left to right, top to
    /// bottom and joined with spaces.
    case plain = "plain"

    /// The grouped layout. Recongized text is first clustered and then each
    /// cluster's obervations are sorted left to right, top to bottom and joined
    /// with spaces.
    case grouped = "grouped"

    /// Is the results layout in beta?
    public var isBeta: Bool {
        switch self {
        case .plain:
            return false

        case .grouped:
            return true
        }
    }
}
