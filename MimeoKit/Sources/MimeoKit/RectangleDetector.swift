import Iris
import Vision

/// A rectangle detector.
public struct RectangleDetector {

    /// Detect rectangles in an image.
    /// - Parameters:
    ///   - image: The image in which to detect rectangles.
    ///   - completion: Called when rectangle detection completes. Detected
    ///     rectangles are passed as quadrilaterals.
    public static func detectRectangles(
        in image: CGImage,
        completion: @escaping ([Quadrilateral]) -> Void

    ) {
        let handler = VNImageRequestHandler(
            cgImage: image,
            options: [:]
        )

        detectRectangles(using: handler, completion: completion)
    }

    /// Detect rectangles in a pixel buffer.
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer in which to detect rectangles.
    ///   - completion: Called when rectangle detection completes. Detected
    ///     rectangles are passed as quadrilaterals.
    public static func detectRectangles(
        in pixelBuffer: CVPixelBuffer,
        completion: @escaping ([Quadrilateral]) -> Void
    ) {
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up
        )

        detectRectangles(using: handler, completion: completion)
    }

    private static func detectRectangles(
        using handler: VNImageRequestHandler,
        completion: @escaping ([Quadrilateral]) -> Void
    ) {
        // Create a Vision rectangle detection request for running on the GPU.
        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation] else {
                return
            }

            completion(results)
        }

        request.maximumObservations = 4
        request.minimumConfidence = 0.9
        request.usesCPUOnly = false

        DispatchQueue.global().async {
            try? handler.perform([request])
        }
    }

}
