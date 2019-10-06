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

public struct TextRecognizer {

    public static func text(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        minimumConfidence: Float = 0.8,
        completion: @escaping (String) -> Void
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
                guard recognizedText.confidence > minimumConfidence else {
                    return nil
                }

                return recognizedText.string
            })

            completion(recognizedStrings.reduce(into: "", { string, recognizedText in
                string.append(" \(recognizedText)")
            }))
        }

        try handler.perform([request])
    }

}
