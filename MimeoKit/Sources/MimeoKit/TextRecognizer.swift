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

    public struct RecognizedTextResult: Equatable {

        public let observations: [VNRecognizedTextObservation]

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

    }

    /// The text recognizer's recognition queue.
    private let textRecognitionQueue = DispatchQueue(
        label: "Text Recognition Queue",
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

    @discardableResult public func recognizeText(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        minimumConfidence: Float = 0.49,
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        usesLanguageCorrection: Bool = true,
        completion: @escaping (RecognitionState) -> Void
    ) throws -> [VNImageBasedRequest] {
        let dispatchGroup = DispatchGroup()

        var fontClassifications = [FontClassifier.Classification]()
        var recognizedTextResult: RecognizedTextResult?

        dispatchGroup.enter()
        let textObservationsRequest = try textObservations(
            in: image,
            orientation: orientation,
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
                    in: UIImage(cgImage: image, scale: 1, orientation: orientation.imageOrientation),
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
        let recognizedTextObservationsRequest = try recognizedTextObservations(
            in: image,
            orientation: orientation,
            minimumConfidence: minimumConfidence,
            recognitionLevel: recognitionLevel,
            usesLanguageCorrection: usesLanguageCorrection,
            completion: { recognitionState in
                switch recognitionState {
                case .notStarted, .inProgress:
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

        return [textObservationsRequest, recognizedTextObservationsRequest]
    }

    /// Returns the text recognized in the specified `image` as a concatination
    /// of all recognized strings with a confidence greater than
    /// `minimumConfidence`, sorted left to right, top to bottom.
    ///
    /// - Parameter image: The image in which to recognize text.
    /// - Parameter orientation: The `image`'s orientation
    /// - Parameter minimumConfidence: The minimum confidence required for a
    ///   text recognition result to be included in the output.
    /// - Parameter completion: The completion handler called when recognition
    ///   state changes.
    @discardableResult public func recognizedTextObservations(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        minimumConfidence: Float = 0.49,
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        usesLanguageCorrection: Bool = true,
        completion: @escaping (RecognitionState) -> Void
    ) throws -> VNRecognizeTextRequest {
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
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

        request.recognitionLevel = recognitionLevel
        request.usesLanguageCorrection = usesLanguageCorrection

        completion(.inProgress)

        textRecognitionQueue.async {
            try? handler.perform([request])
        }

        return request
    }

    /// Detect text rectangles in an image.
    ///
    /// Results include character boxes.
    ///
    /// - Parameter image: The image in which to detect text rectangles.
    /// - Parameter orientation: The image's orientation.
    /// - Parameter minimumConfidence: The minimum confidence required for a
    ///   text rectangle result to be included in the output.
    /// - Parameter completion: The completion handler call when the detection
    ///   is complete.
    @discardableResult private func textObservations(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        minimumConfidence: Float = 0.49,
        completion: @escaping ([VNTextObservation]) -> Void
    ) throws -> VNDetectTextRectanglesRequest {
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        let request = VNDetectTextRectanglesRequest { request, error in
            guard error == nil else {
                return
            }

            guard let results = request.results as? [VNTextObservation] else {
                return
            }

            let textObservations = results.filter({ textObservation in
                return textObservation.confidence > minimumConfidence
            })

            completion(textObservations)
        }

        request.reportCharacterBoxes = true

        textRecognitionQueue.async {
            try? handler.perform([request])
        }

        return request
    }

}
