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
    public static var defaultPreference: RecognitionLanguage = .en_US

    /// The supported languages.
    public static var supportedLanguages: [RecognitionLanguage] {
        let supportedLanguages = try? VNRecognizeTextRequest.supportedRecognitionLanguages(
            for: PreferencesStore.default().get(QuickRecognitionSetting.self).recognitionLevel,
            revision: VNRecognizeTextRequestRevision2
        )

        return (supportedLanguages ?? []).compactMap(RecognitionLanguage.init)
    }

    /// German Germany
    case de_DE = "de-DE"

    /// English U.S.
    case en_US = "en-US"

    /// Spain Spansih
    case es_ES = "es-ES"

    /// French France
    case fr_FR = "fr-FR"

    /// Itialian Italy
    case it_IT = "it-IT"

    /// Brazil Portuguese
    case pt_BR = "pt-BR"

    /// The recognition language's description.
    public var description: String {
        switch self {
        case .de_DE:
            return "German"

        case .en_US:
            return "English"

        case .es_ES:
            return "Spanish"

        case .fr_FR:
            return "French"

        case .it_IT:
            return "Italian"

        case .pt_BR:
            return "Portuguese"
        }
    }

    /// The recognition language's region
    public var region: String {
        switch self {
        case .de_DE:
            return "Germany"

        case .en_US:
            return "United States"

        case .es_ES:
            return "Spain"

        case .fr_FR:
            return "France"

        case .it_IT:
            return "Italy"

        case .pt_BR:
            return "Brazil"
        }
    }

    /// The recognition language's description with region.
    public var descriptionWithRegion: String {
        return "\(description) (\(region))"
    }

}
