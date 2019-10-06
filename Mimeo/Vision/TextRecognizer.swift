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

    /// The text recognizer successfully recognized text.
    /// - Parameter textRecognizer: The text recognizer.
    /// - Parameter recognizedText: The recognized text.
    func textRecognizer(
        _ textRecognizer: TextRecognizer,
        didRecognizeText recognizedText: String
    )

}

/// A text recognizer.
public final class TextRecognizer {

    /// The text recognizer's delegate.
    public weak var delegate: TextRecognizerDelegate?

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
    ) throws {
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil else {
                return
            }

            guard let results = request.results as? [VNRecognizedTextObservation] else {
                return
            }

            let resultsLeftToRightTopToBottom = results.sorted(by: { lhs, rhs -> Bool in
                return lhs.topLeft.x < rhs.topLeft.x && lhs.topLeft.y > rhs.topLeft.y
            })

            let topCandidates = resultsLeftToRightTopToBottom.map({ recognizedTextObservation in
                return recognizedTextObservation.topCandidates(1).first!
            })

            let recognizedStrings = topCandidates.compactMap({ recognizedText -> String? in
                print(recognizedText.string)
                guard recognizedText.confidence > minimumConfidence else {
                    return nil
                }

                return recognizedText.string
            })

            self.delegate?.textRecognizer(self, didRecognizeText: recognizedStrings.reduce(into: "", { string, recognizedText in
                string.append(" \(recognizedText)")
            }))
        }

        try handler.perform([request])
    }

}
