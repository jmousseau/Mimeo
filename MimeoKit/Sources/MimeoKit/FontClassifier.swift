import Iris
import Foundation
import FontClassifier
import Vision

extension FontClassifier {

    /// Create a character image for a random set of character boxes found
    /// inside each of the given clustered text observations.
    ///
    /// Every character image will have dark text on a white background.
    ///
    /// - Parameter image: The image in which the clusterd observations and
    ///   character boxes exist.
    /// - Parameter clusteredObservations: The clustered text observations in
    ///   the image.
    /// - Parameter characterImageSize: The desired character image size.
    /// - Parameter characterImageInsets: The desired character image insets.
    /// - Parameter characterImageSampleCount: The number of character boxes to
    ///   sample from each cluster.
    /// - Parameter completionQueue: The queue on which to call the completion
    ///   handler.
    /// - Parameter completion: Completion handler called with the sampled
    ///   character images indexed by the observation clusters.
    public static func sampleCharacterImages(
        in image: Image,
        with clusteredObservations: [[VNTextObservation]],
        characterImageSize: CGSize,
        characterImageInsets: EdgeInsets = .zero,
        characterImageSampleCount: Int = .max,
        completionQueue: DispatchQueue,
        completion: @escaping ([[Image]]) -> Void
    ) {
        let dispatchGroup = DispatchGroup()

        var clustedCharacterImages = [[Image]]()

        for observations in clusteredObservations {
            dispatchGroup.enter()

            sampleCharacterImages(
                in: image,
                with: observations,
                characterImageSize: characterImageSize,
                characterImageInsets: characterImageInsets,
                characterImageSampleCount: characterImageSampleCount,
                completion: { characterImages in
                    clustedCharacterImages.append(characterImages)
                    dispatchGroup.leave()
                }
            )
        }

        dispatchGroup.notify(queue: completionQueue) {
            completion(clustedCharacterImages)
        }
    }

}
