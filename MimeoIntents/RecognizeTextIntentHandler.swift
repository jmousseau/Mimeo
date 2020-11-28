//
//  RecognizeTextIntentHandler.swift
//  MimeoIntents
//
//  Created by Jack Mousseau on 10/18/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Intents
import MimeoKit
import UIKit

/// A recognize text intent handler.
public final class RecognizeTextIntentHandler: NSObject, RecognizeTextIntentHandling {

    public func handle(
        intent: RecognizeTextIntent,
        completion: @escaping (RecognizeTextIntentResponse) -> Void
    ) {
        guard let data = intent.image?.data, data.count <= 70_000 else {
            completion(RecognizeTextIntentResponse(code: .largeImage, userActivity: nil))
            return
        }

        guard let image = UIImage(data: data),
            let cgImage = image.cgImage else {
                completion(RecognizeTextIntentResponse(code: .failure, userActivity: nil))
                return
        }

        let shouldGroup = intent.shouldGroup as? Bool ?? false
        let textRecognizer = TextRecognizer()

        textRecognizer.recognizeText(
            in: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            recognitionLevel: .fast,
            recognitionLanguage: intent.language.recognitionLanguage,
            usesLanguageCorrection: false
        ) { recognitionState in
            switch (recognitionState, shouldGroup) {
            case (.notStarted, _), (.inProgress, _):
                break

            case (.complete(let result), false):
                let response = RecognizeTextIntentResponse(code: .success, userActivity: nil)
                response.text = result.observations.plainText()
                completion(response)

            case (.complete(let result), true):
                let response = RecognizeTextIntentResponse(code: .success, userActivity: nil)
                response.text = result.observations.groupedText().joined(separator: "\n")
                completion(response)

            case (.failed, _):
                completion(RecognizeTextIntentResponse(
                    code: .failure, userActivity: nil
                ))
            }
        }
    }

    public func resolveImage(
        for intent: RecognizeTextIntent,
        with completion: @escaping (INFileResolutionResult) -> Void
    ) {
        guard let image = intent.image else {
            return
        }

        completion(.success(with: image))
    }

    public func resolveLanguage(
        for intent: RecognizeTextIntent,
        with completion: @escaping (LanguageResolutionResult) -> Void
    ) {
        completion(.success(with: intent.language))
    }

    public func resolveShouldGroup(
        for intent: RecognizeTextIntent,
        with completion: @escaping (INBooleanResolutionResult) -> Void
    ) {
        completion(.success(with: intent.shouldGroup as? Bool ?? false))
    }

}

extension Language {

    // The recognition language used for text recognition.
    var recognitionLanguage: String {
        switch self {
        case .unknown:
            return "en-US"

        case .de_DE:
            return "de-DE"

        case .en_US:
            return "en-US"

        case .es_ES:
            return "es-ES"

        case .fr_FR:
            return "fr-FR"

        case .it_IT:
            return "it-IT"

        case .pt_BR:
            return "pt-BR"
        }
    }

}
