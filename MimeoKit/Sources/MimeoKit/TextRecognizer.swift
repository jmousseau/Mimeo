//
//  TextRecognizer.swift
//  MimeoKit
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Iris
import FontClassifier
import UIKit
import Vision

/// A text recognizer.
@available(iOS 13.0, *)
public final class TextRecognizer {

    /// A recognized text result.
    public struct RecognizedTextResult: Equatable {

        /// The recognized text result's observations.
        public let observations: [VNRecognizedTextObservation]

        /// The recognized text result's font classification.
        public fileprivate(set) var fontClassification: FontClassifier.Classification? = nil

    }

    /// A text recognition state.
    public enum RecognitionState: Equatable {

        /// Recognition has not started.
        case notStarted

        /// The recognition algorithm is in progress.
        case inProgress

        /// The recognition process completed.
        case complete(result: RecognizedTextResult)

        /// The recognition process failed.
        case failed

    }

    /// Recognized text in an image.
    /// - Parameters:
    ///   - minimumConfidence: The minimum confidence required for a text
    ///     recognition result to be included in the output.
    ///   - recognitionLevel: The recognition level with which to recognize
    ///     text.
    ///   - usesLanguageCorrection: Should language correction be performed on
    ///     the recognized text.
    ///   - completion: The completion handler called when recognition state
    ///     changes.
    @discardableResult public static func recognizedTextObservationsRequest(
        minimumConfidence: Float = 0.49,
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        recognitionLanguage: String,
        usesLanguageCorrection: Bool = true,
        completion: @escaping (RecognitionState) -> Void
    ) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                return
            }

            guard let results = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let recognizedTextObservations = results.filter({ recognizedTextObservation in
                guard let topCandidate = recognizedTextObservation.topCandidate else {
                    return false
                }

                return topCandidate.confidence > minimumConfidence
            })

            completion(.complete(
                result: RecognizedTextResult(
                    observations: recognizedTextObservations
                )
            ))
        }

        request.revision = VNRecognizeTextRequestRevision2
        request.recognitionLevel = recognitionLevel
        request.usesLanguageCorrection = usesLanguageCorrection

        completion(.inProgress)

        return request
    }

    /// The text recognizer's recognition queue.
    private let textRecognitionQueue = DispatchQueue(
        label: "Text Recognition Queue",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private let fontClassifier: FontClassifier?

    /// Initialize a new text recognizer.
    public init() {
        fontClassifier = nil
    }

    /// Initialize a new text recognizer.
    ///
    /// - Parameter fontClassifierModel: The text recognizer's font classifier
    ///   model.
    public init(fontClassifierModel: MLModel) throws {
        fontClassifier = try FontClassifier(model: fontClassifierModel)
    }

    // TODO: Ideally, this would just construct the necessary Vision image based
    // requests. However, the font classifier does not itself construct a
    // request.

    /// Recognized text in a given image.
    /// - Parameters:
    ///   - image: The image in which to recognized text
    ///   - orientation: The image's orientation.
    ///   - minimumConfidence: The minimum confidence required for a text
    ///     recognition result to be included in the output.
    ///   - recognitionLevel: The recognition level with which to recognize
    ///     text.
    ///   - usesLanguageCorrection: Should language correction be performed on
    ///     the recognized text.
    ///   - completion: The completion handler called when the recognition state
    ///     changes.
    @discardableResult public func recognizeText(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        minimumConfidence: Float = 0.49,
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        recognitionLanguage: String,
        usesLanguageCorrection: Bool = true,
        completion: @escaping (RecognitionState) -> Void
    ) -> [VNImageBasedRequest] {
        let dispatchGroup = DispatchGroup()

        var fontClassifications = [FontClassifier.Classification]()
        var recognizedTextResult: RecognizedTextResult?

        dispatchGroup.enter()
        let textObservationsRequest = TextDetector.textObservationsRequest(
            minimumConfidence: minimumConfidence,
            completion: { textObservations in
                defer {
                    dispatchGroup.leave()
                }

                if self.fontClassifier == nil {
                    return
                }

                dispatchGroup.enter()
                FontClassifier.sampleCharacterImages(
                    in: UIImage(
                        cgImage: image,
                        scale: 1,
                        orientation: orientation.imageOrientation
                    ),
                    with: textObservations,
                    characterImageSize: CGSize(width: 300, height: 300),
                    characterImageSampleCount: 5
                ) { sampledCharacterImages in
                    defer {
                        dispatchGroup.leave()
                    }

                    for characterImage in sampledCharacterImages.compactMap({ image in
                        image.cgImage
                    }) {
                        dispatchGroup.enter()

                        do {
                            try self.fontClassifier?.classify(
                                characterImage: characterImage
                            ) { fontClassification in
                                defer {
                                    dispatchGroup.leave()
                                }

                                fontClassifications.append(fontClassification)
                            }
                        } catch {
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        )

        dispatchGroup.enter()
        let recognizedTextObservationsRequest = Self.recognizedTextObservationsRequest(
            minimumConfidence: minimumConfidence,
            recognitionLevel: recognitionLevel,
            recognitionLanguage: recognitionLanguage,
            usesLanguageCorrection: usesLanguageCorrection,
            completion: { recognitionState in
                switch recognitionState {
                case .notStarted, .inProgress, .failed:
                    completion(recognitionState)

                case .complete(let result):
                    recognizedTextResult = result
                    dispatchGroup.leave()
                }
            }
        )

        dispatchGroup.notify(queue: textRecognitionQueue) {
            let serifClassificationCount = fontClassifications.reduce(0) { serifCount, classification in
                serifCount + (classification == .serif ? 1 : 0)
            }

            let areMajoritySerif = Float(serifClassificationCount) / Float(fontClassifications.count) > 0.5
            recognizedTextResult?.fontClassification = areMajoritySerif ? .serif : .sansSerif
            completion(.complete(result: recognizedTextResult!))
        }

        let textRecognitionRequests = [
            textObservationsRequest,
            recognizedTextObservationsRequest
        ]

        textRecognitionQueue.async {
            try? VNImageRequestHandler(
                cgImage: image,
                orientation: orientation
            ).perform(textRecognitionRequests)
        }

        return textRecognitionRequests
    }

}
