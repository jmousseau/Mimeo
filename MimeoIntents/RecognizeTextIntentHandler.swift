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
        guard let data = intent.image?.data,
            let image = UIImage(data: data),
            let cgImage = image.cgImage else {
                completion(RecognizeTextIntentResponse(code: .failure, userActivity: nil))
                return
        }

        let shouldGroup = intent.shouldGroup as? Bool ?? false
        let textRecognizer = TextRecognizer()

        do {
            try textRecognizer.recognizeText(
                in: cgImage,
                orientation: CGImagePropertyOrientation(image.imageOrientation),
                recognitionLevel: .fast,
                usesLanguageCorrection: false
            ) { recognitionState in
                switch (recognitionState, shouldGroup) {
                case (.notStarted, _), (.inProgress, _):
                    break

                case (.complete(let recognizedTextObservations), false):
                    let response = RecognizeTextIntentResponse(code: .success, userActivity: nil)
                    response.text = recognizedTextObservations.plainText()
                    completion(response)

                case (.complete(let recognizedTextObservations), true):
                    let response = RecognizeTextIntentResponse(code: .success, userActivity: nil)
                    response.text = recognizedTextObservations.groupedText().joined(separator: "\n")
                    completion(response)
                }
            }
        } catch {
            completion(RecognizeTextIntentResponse(code: .failure, userActivity: nil))
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

    public func resolveShouldGroup(
        for intent: RecognizeTextIntent,
        with completion: @escaping (INBooleanResolutionResult) -> Void
    ) {
        completion(.success(with: intent.shouldGroup as? Bool ?? false))
    }

}
