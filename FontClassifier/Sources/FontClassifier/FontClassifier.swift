import CoreGraphics
import Foundation
import Iris
import Vision

@available(iOS 13, macOS 10.15, *)
public struct FontClassifier {

    /// Create a character image for a random set of character boxes found
    /// inside the given text observations.
    ///
    /// Every character image will have dark text on a white background.
    ///
    /// - Parameter image: The image in which the observations and character
    ///   boxes exist.
    /// - Parameter observations: The text observations in the image.
    /// - Parameter characterImageSize: The desired character image size.
    /// - Parameter characterImageInsets: The desired character image insets.
    /// - Parameter characterImageSampleCount: The number of character boxes to
    ///   sample.
    /// - Parameter completion: Completion handler called with the sampled
    ///   character images.
    public static func sampleCharacterImages(
        in image: Image,
        with observations: [VNTextObservation],
        characterImageSize: CGSize,
        characterImageInsets: EdgeInsets = .zero,
        characterImageSampleCount: Int = .max,
        completion: @escaping ([Image]) -> Void
    ) {
        let sampledCharacterBoxes = Array(observations.reduce([], { characterBoxes, observation in
            characterBoxes + (observation.characterBoxes ?? [])
        }).shuffled().prefix(characterImageSampleCount))

        characterImages(
            in: image,
            with: observations,
            characterBoxes: sampledCharacterBoxes,
            characterImageSize: characterImageSize,
            characterImageInsets: characterImageInsets,
            completion: completion
        )
    }

    /// Create a character image for every character box found inside the given
    /// text obervations.
    ///
    /// Every character image will have dark text on a white background.
    ///
    /// - Parameter image: The image in which the observations and character
    ///   boxes exist.
    /// - Parameter observations: The text observations in the image.
    /// - Parameter characterImageSize: The desired character image size.
    /// - Parameter characterImageInsets: The desired character image insets.
    /// - Parameter completion: Completion handler called with all character
    ///   images.
    public static func characterImages(
        in image: Image,
        with observations: [VNTextObservation],
        characterImageSize: CGSize,
        characterImageInsets: EdgeInsets = .zero,
        completion: @escaping ([Image]) -> Void
    ) {
        let allCharacterBoxes = observations.reduce([]) { characterBoxes, observation in
            characterBoxes + (observation.characterBoxes ?? [])
        }

        characterImages(
            in: image,
            with: observations,
            characterBoxes: allCharacterBoxes,
            characterImageSize: characterImageSize,
            characterImageInsets: characterImageInsets,
            completion: completion
        )
    }

    /// Create a character image for each character box.
    ///
    /// Every character image will have dark text on a white background.
    ///
    /// - Parameter image: The image in which the observations and character
    ///   boxes exist.
    /// - Parameter observations: The text observations in the image.
    /// - Parameter characterBoxes: The character boxes for which to return
    ///   character images.
    /// - Parameter characterImageSize: The desired character image size.
    /// - Parameter characterImageInsets: The desired character image insets.
    /// - Parameter completion: Completion handler called with all character
    ///   images.
    public static func characterImages(
        in image: Image,
        with observations: [VNRectangleObservation],
        characterBoxes: [VNRectangleObservation],
        characterImageSize: CGSize,
        characterImageInsets: EdgeInsets = .zero,
        completion: @escaping ([Image]) -> Void
    ) {
        let color = monoBackgroundColor(of: image, observations: observations)
        let isDarkBackground = (color?.hsba.brightness ?? 1) < 0.5

        var characterImages = [Image]()

        for characterBox in characterBoxes {
            guard let characterImage = image.crop(
                to: characterBox.boundingBox
                    .inNormalizedUIImageCoordinateSpace()
                    .denormalize(for: image.size)
            ) else {
                continue
            }

            let contrast: CGFloat = isDarkBackground ? 1.8 : 9
            let brightness: CGFloat = isDarkBackground ? 0 : 3.5

            guard var monoCharacterImage = ImageFilter.highContrastMono(
                contrast: contrast,
                brightness: brightness
            ).apply(
                to: characterImage
            ) else {
                continue
            }

            if isDarkBackground,
                let invertedCharacterImage = ImageFilter.invertColor.apply(to: monoCharacterImage) {
                monoCharacterImage = invertedCharacterImage
            }

            guard let scaledCharacterImage = monoCharacterImage.draw(
                at: characterImageSize,
                insets: characterImageInsets
            ) else {
                continue
            }

            characterImages.append(scaledCharacterImage)
        }

        completion(characterImages)
    }

    /// Determine the mono background color in a given image behind given text
    /// obervations.
    /// - Parameter image: The image for which to determine the background color
    ///   behind the text observations.
    /// - Parameter observations: The text observations for the given image.
    public static func monoBackgroundColor(
        of image: Image,
        observations: [VNRectangleObservation]
    ) -> Color? {
        let boundingBox = observations
            .boundingBox()
            .inNormalizedUIImageCoordinateSpace()
            .denormalize(for: image.size)

        let expandedBoundingBox = boundingBox.expanded(
            by: EdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        )

        guard let expandedImage = image.crop(to: expandedBoundingBox) else {
            return nil
        }

        guard let highContrastImage = ImageFilter.highContrastMono(
            contrast: 1.8,
            brightness: 0
        ).apply(
            to: expandedImage
        ) else {
            return nil
        }

        let colors = expandedBoundingBox.borderRects(
            to: boundingBox.inCoordinateSpace(of: expandedBoundingBox.origin)
        ).compactMap({ borderRect -> Color? in
            guard let borderImage = ImageFilter.crop(
                rect: borderRect
            ).apply(to: highContrastImage) else {
                return nil
            }

            guard let averageBorderColorImage = ImageFilter.averageColor.apply(
                to: borderImage
            ) else {
                return nil
            }

            return averageBorderColorImage.topLeftPixelColor
        })

        return colors.average()
    }

    public enum Classification: String {

        case serif = "serif"

        case sansSerif = "sans-serif"

    }

    private let model: VNCoreMLModel

    /// Initialize a font classifier.
    /// - Parameter model: The font classifier's CoreML model.
    public init(model: MLModel) throws {
        self.model = try VNCoreMLModel(for: model)
    }

    public func classify(
        characterImage: CGImage,
        completion: @escaping (Classification) -> Void
    ) throws {
        let handler = VNImageRequestHandler(
            cgImage: characterImage,
            orientation: .up
        )

        let request = VNCoreMLRequest(model: model) { request, error in
            guard let observation = request.results?.first as? VNClassificationObservation else {
                return
            }

            completion(Classification(rawValue: observation.identifier) ?? .serif)
        }

        request.imageCropAndScaleOption = .scaleFit

        try handler.perform([request])
    }

}
