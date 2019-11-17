import Iris
import UIKit

// A rectangle cropper.
public struct ImageCropper {

    /// A rectangle comparison method.
    public enum RectangleComparisonMethod {

        /// The rectangle's area is used to compare rectangles.
        case area

        /// The rectangle's perimeter is used to compare rectangles.
        case perimeter

    }

    /// Crop an image to the largest rectangle detected in the image.
    /// - Parameters:
    ///   - image: The image to compare
    ///   - comparisonMethod: The comparison method used to determine which
    ///     detected rectangle is the largest. Default's to `area`.
    ///   - completion: The completion handler called with the cropped image, or
    ///     `nil` if no rectangle was detected.
    public static func cropToLargestRectangle(
        in image: UIImage,
        by comparisonMethod: RectangleComparisonMethod = .area,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        RectangleDetector.detectRectangles(
            in: cgImage
        ) { quadrilaterals in
            guard let quadrilateral = quadrilaterals.sorted(by: { lhs, rhs in
                switch comparisonMethod {
                case .area:
                    return lhs.area > rhs.area

                case .perimeter:
                    return lhs.perimeter > rhs.perimeter
                }
            }).first else {
                completion(nil)
                return
            }


            guard let autocroppedImage = ImageFilter.correct(
                perspective: quadrilateral.denormalize(for: image.size)
            ).apply(to: image) else {
                completion(nil)
                return
            }

            completion(autocroppedImage)
        }
    }

}

