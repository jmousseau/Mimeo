//
//  RecognitionLanguage.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import Vision

public enum RecognitionLanguage: String, PreferenceStorable {

    /// The recognition language preference key.
    public static var preferenceKey: String = "recognition-language"

    /// The default language preference.
    public static var defaultPreferenceValue: RecognitionLanguage = .en_US

    /// The supported languages.
    public static var supportedLanguages: [RecognitionLanguage] {
        let supportedLanguages = try? VNRecognizeTextRequest.supportedRecognitionLanguages(
            for: PreferencesStore.default().get(QuickRecognitionSetting.self).recognitionLevel,
            revision: VNRecognizeTextRequestRevision1
        )

        return (supportedLanguages ?? []).compactMap(RecognitionLanguage.init)
    }

    /// English U.S.
    case en_US = "en-US"

    /// The recognition language's description.
    public var description: String {
        switch self {
        case .en_US:
            return "English"
        }
    }

    /// The recognition language's region
    public var region: String {
        switch self {
        case .en_US:
            return "United States"
        }
    }

    /// The recognition language's description with region.
    public var descriptionWithRegion: String {
        return "\(description) (\(region))"
    }

}
