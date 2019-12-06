import Iris
import Vision

/// A rectangle detector.
public struct RectangleDetector {

    /// Detect rectangles in an image.
    /// - Parameters:
    ///   - completion: Called when rectangle detection completes. Detected
    ///     rectangles are passed as quadrilaterals.
    public static func detectRectanglesRequest(
        completion: @escaping ([Quadrilateral]) -> Void
    ) -> VNImageBasedRequest {
        // Create a Vision rectangle detection request for running on the GPU.
        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation] else {
                return
            }

            completion(results)
        }

        request.maximumObservations = 4
        request.minimumConfidence = 0.9

        return request
    }

}
