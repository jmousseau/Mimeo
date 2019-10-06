//
//  TextRecognizer.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import UIKit
import Vision

/// The text recognizer delegate.
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
public final class TextRecognizer {

    /// A text recognition state.
    public enum RecognitionState: Equatable {

        /// Recognition has not started.
        case notStarted

        /// The recognition algorithm is in progress.
        case inProgress

        /// The recognition process completed.
        case complete(recognizedText: String)

    }

    /// The text recognizer's delegate.
    public weak var delegate: TextRecognizerDelegate?

    /// The text recognizer's recognition queue.
    private let textRecognitionQueue = DispatchQueue(label: "Text Recognition Queue")

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
        minimumConfidence: Float = 0.8
    ) throws -> VNRecognizeTextRequest {
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                return
            }

            guard let results = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let resultsLeftToRightTopToBottom = results.sortedLeftToRightTopToBottom()

            let topCandidates = resultsLeftToRightTopToBottom.map({ recognizedTextObservation in
                return recognizedTextObservation.topCandidate!
            })

            let recognizedStrings = topCandidates.compactMap({ recognizedText -> String? in
                print(recognizedText.string)
                guard recognizedText.confidence > minimumConfidence else {
                    return nil
                }

                return recognizedText.string
            })

            let allRecognizedText = recognizedStrings.reduce(into: "", { string, recognizedText in
                string.append(" \(recognizedText)")
            })

            self.didUpdateRecognitionState(.complete(recognizedText: allRecognizedText))
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
