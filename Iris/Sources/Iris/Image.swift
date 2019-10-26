import AVFoundation

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias Image = UIImage

extension CGImagePropertyOrientation {

    /// Initialize a CGImage orientation for a given UIImage orientation.
    /// - Parameter orientation: The UIImage orientation.
    public init(_ orientation: Image.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }

}

#elseif os(macOS)

import Cocoa
import SDWebImage

public typealias Image = NSImage

extension Image {

    public var imageOrientation: CGImagePropertyOrientation {
        return .up
    }

}

#endif

// MARK: - UIImage

extension Image {

    /// Crop the image to a rectangle.
    /// - Parameter rect: The rectangle with which to crop the image.
    public func crop(to rect: CGRect) -> Image? {
        guard let cropped = cgImage?.cropping(to: rect) else {
            return nil
        }

        return Image(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }

    /// Draw the image inside a rectangle with a given size, insets, and
    /// background color.
    /// - Parameter size: The drawn image's size.
    /// - Parameter insets: The drawn image's insets.
    /// - Parameter backgroundColor: The drawn image's background color.
    ///   Defaults to white.
    @available(iOS 10.0, *)
    public func draw(
        at size: CGSize,
        insets: EdgeInsets,
        withBackgroundColor backgroundColor: Color = .white
    ) -> Image? {
        let imageRendererFormat = GraphicsImageRendererFormat()
        imageRendererFormat.scale = 1

        let imageRenderer = GraphicsImageRenderer(
            size: size,
            format: imageRendererFormat
        )

        let bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)

        return imageRenderer.image(actions: { context in
            backgroundColor.setFill()
            context.fill(bounds)
            self.draw(in: AVMakeRect(
                aspectRatio: self.size,
                insideRect: bounds.contracted(by: insets)
            ))
        })
    }

    /// The color of the image's top left pixel.
    public var topLeftPixelColor: Color? {
        guard let image = cgImage else {
            return nil
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(
            CIImage(cgImage: image),
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return Color(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )
    }

}
