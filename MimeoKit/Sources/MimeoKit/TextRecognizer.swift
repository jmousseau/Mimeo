//
//  TextRecognizer.swift
//  MimeoKit
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import UIKit
import Vision

/// The text recognizer delegate.
@available(iOS 13.0, *)
public protocol TextRecognizerDelegate: class {

    /// The text recognizer did update the recognition state.
    /// - Parameter textRecognizer: The text recognizer.
    /// - Parameter recognitionState: The recognition state.
    func textRecognizer(
        _ textRecognizer: TextRecognizer,
        didUpdateRecognitionState recognitionState: TextRecognizer.RecognitionState
    )

}

/// A text recognizer.
@available(iOS 13.0, *)
public final class TextRecognizer {

    /// A text recognition state.
    public enum RecognitionState: Equatable {

        /// Recognition has not started.
        case notStarted

        /// The recognition algorithm is in progress.
        case inProgress

        /// The recognition process completed.
        case complete(recognizedTextObservations: [VNRecognizedTextObservation])

    }

    /// The text recognizer's delegate.
    public weak var delegate: TextRecognizerDelegate?

    /// The text recognizer's recognition queue.
    private let textRecognitionQueue = DispatchQueue(label: "Text Recognition Queue")

    /// Initialize a new text recognizer.
    public init() { }

    /// Returns the text recognized in the specified `image` as a concatination
    /// of all recognized strings with a confidence greater than
    /// `minimumConfidence`, sorted left to right, top to bottom.
    /// - Parameter image: The image in which to recognize text.
    /// - Parameter orientation: The `image`'s orientation
    /// - Parameter minimumConfidence: The minimum confidence required for a
    /// text recognition result to be included in the output.
    /// - Parameter completion: The completion handler called when recognition
    /// is finished.
    public func recognizeText(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        minimumConfidence: Float = 0.49
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

            self.didUpdateRecognitionState(.complete(
                recognizedTextObservations: recognizedTextObservations
            ))
        }

        self.didUpdateRecognitionState(.inProgress)
        textRecognitionQueue.async {
            try? handler.perform([request])
        }

        return request
    }

    private func didUpdateRecognitionState(_ recognitionState: RecognitionState) {
        DispatchQueue.main.async {
            self.delegate?.textRecognizer(self, didUpdateRecognitionState: recognitionState)
        }
    }

}
