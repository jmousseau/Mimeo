#if targetEnvironment(macCatalyst) || os(iOS)

import UIKit

// MARK: - Image Filter

/// An image filter.
@available(iOS 10.0, *)
public enum ImageFilter {

    /// Average color of an image.
    case averageColor

    /// Crop an image.
    case crop(rect: CGRect)

    /// High contrast mono image.
    case highContrastMono(contrast: CGFloat, brightness: CGFloat)

    /// Invert color of image.
    case invertColor

    /// Subtract a rectangular area from an image.
    case subtract(rect: CGRect)

    public func apply(to image: UIImage) -> UIImage? {
        guard let image = image.cgImage else {
            return nil
        }

        switch self {
        case .averageColor:
            return applyAverageColorFilter(to: image)

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

        case .subtract(let rect):
            return applySubtractFilter(to: image, rect: rect)
        }
    }

    // MARK: - Average Color Filter

    func applyAverageColorFilter(to image: CGImage) -> UIImage? {
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

    // MARK: - Crop Filter

    private func applyCropFilter(to image: CGImage, rect: CGRect) -> UIImage? {
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
    ) -> UIImage? {
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

    func applyInvertColorFilter(to image: CGImage) -> UIImage? {
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

    @available(iOS 10.0, *)
    private func applySubtractFilter(to image: CGImage, rect: CGRect) -> UIImage? {
        let backgroundImageSize = CGSize(
            width: image.width,
            height: image.height
        )

        let backgroundImageRendererFormat = UIGraphicsImageRendererFormat()
        backgroundImageRendererFormat.scale = 1

        let backgroundImageRenderer = UIGraphicsImageRenderer(
            size: backgroundImageSize,
            format: backgroundImageRendererFormat
        )

        guard let backgroundImage = backgroundImageRenderer.image(actions: { context in
            UIColor.white.setFill()
            context.fill(rect)
        }).cgImage else {
            return nil
        }

        guard let subtractFilter = CIFilter(name: "CISourceOutCompositing") else {
            return nil
        }

        subtractFilter.setValuesForKeys([
            kCIInputBackgroundImageKey: CIImage(cgImage: backgroundImage),
            kCIInputImageKey: CIImage(cgImage: image)
        ])

        guard let subtractImage = subtractFilter.outputImage else {
            return nil
        }

        return self.image(for: subtractImage)
    }

    private func image(for image: CIImage) -> UIImage? {
        let context = CIContext()

        guard let cgImage = context.createCGImage(
            image,
            from: image.extent
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

}

#endif
