import CoreGraphics
import CoreImage
import Foundation

// MARK: - Image Filter

/// An image filter.
@available(iOS 11.0, *)
public enum ImageFilter {

    /// Average color of an image.
    case averageColor

    /// Correct the image's perspective
    case correct(perspective: Quadrilateral)

    /// Crop an image.
    case crop(rect: CGRect)

    /// High contrast mono image.
    case highContrastMono(contrast: CGFloat, brightness: CGFloat)

    /// Invert color of image.
    case invertColor

    /// Subtract rectangular areas from an image. Inverting the filter will
    /// subtract everything but the rectangular areas from the image.
    case subtract(rects: [CGRect], invert: Bool = false)

    public func apply(to image: Image) -> Image? {
        guard let image = image.cgImage else {
            return nil
        }

        switch self {
        case .averageColor:
            return applyAverageColorFilter(to: image)

        case .correct(let perspective):
            return applyCorrectionFilter(to: image, perspective: perspective)

        case .crop(let rect):
            return applyCropFilter(to: image, rect: rect)

        case .highContrastMono(let contrast, let brightness):
            return applyHighContrastMonoFilter(
                to: image,
                contrast: contrast,
                brightness: brightness
            )

        case .invertColor:
            return applyInvertColorFilter(to: image)

        case .subtract(let rects, let invert):
            return applySubtractFilter(to: image, rects: rects, invert: invert)
        }
    }

    // MARK: - Average Color Filter

    func applyAverageColorFilter(to image: CGImage) -> Image? {
        guard let averageColorFilter = CIFilter(name: "CIAreaAverage") else {
            return nil
        }

        let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)

        averageColorFilter.setValuesForKeys([
            kCIInputImageKey: CIImage(cgImage: image),
            kCIInputExtentKey: CIVector(cgRect: imageBounds)
        ])

        guard let averageColorImage = averageColorFilter.outputImage else {
            return nil
        }

        return self.image(for: averageColorImage)
    }

    // MARK: - Correct Perspective

    private func applyCorrectionFilter(
        to image: CGImage,
        perspective: Quadrilateral
    ) -> Image? {
        guard let correctionFilter = CIFilter(name: "CIPerspectiveCorrection") else {
            return nil
        }

        correctionFilter.setValuesForKeys([
            kCIInputImageKey: CIImage(cgImage: image),
            "inputTopLeft": CIVector(cgPoint: perspective.topLeft),
            "inputTopRight": CIVector(cgPoint: perspective.topRight),
            "inputBottomLeft": CIVector(cgPoint: perspective.bottomLeft),
            "inputBottomRight": CIVector(cgPoint: perspective.bottomRight)
        ])

        guard let correctedImage = correctionFilter.outputImage else {
            return nil
        }

        return self.image(for: correctedImage)
    }

    // MARK: - Crop Filter

    private func applyCropFilter(to image: CGImage, rect: CGRect) -> Image? {
        guard let cropFilter = CIFilter(name: "CICrop") else {
            return nil
        }

        cropFilter.setValuesForKeys([
            kCIInputImageKey: CIImage(cgImage: image),
            "inputRectangle": CIVector(cgRect: rect)
        ])

        guard let croppedImage = cropFilter.outputImage else {
            return nil
        }

        return self.image(for: croppedImage)
    }

    // MARK: - High Contrast Mono Filter

    private func applyHighContrastMonoFilter(
        to image: CGImage,
        contrast: CGFloat,
        brightness: CGFloat
    ) -> Image? {
        guard let monoFilter = CIFilter(name: "CIPhotoEffectMono") else {
            return nil
        }

        monoFilter.setValuesForKeys([
            kCIInputImageKey: CIImage(cgImage: image)
        ])

        guard let monoImage = monoFilter.outputImage,
            let contrastFilter = CIFilter(name: "CIColorControls") else {
            return nil
        }

        contrastFilter.setValuesForKeys([
            kCIInputImageKey: monoImage,
            kCIInputContrastKey: contrast,
            kCIInputBrightnessKey: brightness
        ])

        guard let highContrastMonoImage = contrastFilter.outputImage else {
            return nil
        }

        return self.image(for: highContrastMonoImage)
    }

    // MARK: - Invert Color Filter

    func applyInvertColorFilter(to image: CGImage) -> Image? {
        guard let invertColorFilter = CIFilter(name: "CIColorInvert") else {
            return nil
        }

        invertColorFilter.setValuesForKeys([
            kCIInputImageKey: CIImage(cgImage: image)
        ])

        guard let invertColorImage = invertColorFilter.outputImage else {
            return nil
        }

        return self.image(for: invertColorImage)
    }

    // MARK: - Subtract Filter

    private func applySubtractFilter(
        to image: CGImage,
        rects: [CGRect],
        invert: Bool
    ) -> Image? {
        let backgroundImageSize = CGSize(
            width: image.width,
            height: image.height
        )

        let backgroundImageRendererFormat = GraphicsImageRendererFormat()
        backgroundImageRendererFormat.scale = 1

        let backgroundImageRenderer = GraphicsImageRenderer(
            size: backgroundImageSize,
            format: backgroundImageRendererFormat
        )

        guard let backgroundImage = backgroundImageRenderer.image(actions: { context in
            rects.forEach({ rect in
                Color.white.setFill()
                context.fill(rect)
            })
        }).cgImage else {
            return nil
        }

        guard let filter = CIFilter(
            name: invert ? "CISourceInCompositing" : "CISourceOutCompositing"
        ) else {
            return nil
        }

        filter.setValuesForKeys([
            kCIInputBackgroundImageKey: CIImage(cgImage: backgroundImage),
            kCIInputImageKey: CIImage(cgImage: image)
        ])

        guard let outputImage = filter.outputImage else {
            return nil
        }

        return self.image(for: outputImage)
    }

    private func image(for image: CIImage) -> Image? {
        let context = CIContext()

        guard let cgImage = context.createCGImage(
            image,
            from: image.extent
        ) else {
            return nil
        }

        #if os(iOS) || os(tvOS) || os(watchOS)

        return Image(cgImage: cgImage)

        #elseif os(macOS)

        return Image(cgImage: cgImage, size: image.extent.size)

        #endif
    }

}
