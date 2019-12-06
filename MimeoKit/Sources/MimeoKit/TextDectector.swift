import Vision

/// A text detector.
@available(iOS 12.0, *)
public final class TextDetector {

    /// Does a given image contain text?
    /// - Parameters:
    ///   - completion: The completion handler called when the detection is
    ///     complete.
    @discardableResult public static func textExistsRequest(
        completion: @escaping (Bool) -> Void
    ) -> VNDetectTextRectanglesRequest {
        textObservationsRequest(
            reportCharacterBoxes: false
        ) { observations in
            completion(observations.count > 0)
        }
    }

    /// Detect text rectangles in an image.
    /// - Parameters:
    ///   - reportCharacterBoxes: Should chararcher boxes be included in the
    ///     observations?
    ///   - minimumConfidence:  The minimum confidence required for a text
    ///     rectangle result to be included in the output.
    ///   - completion:  The completion handler call when the detection is
    ///     complete.
    @discardableResult public static func textObservationsRequest(
        reportCharacterBoxes: Bool = true,
        minimumConfidence: Float = 0.49,
        completion: @escaping ([VNTextObservation]) -> Void
    ) -> VNDetectTextRectanglesRequest {
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
        request.usesCPUOnly = false

        return request
    }

}
