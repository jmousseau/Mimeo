import AVFoundation

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias Image = UIImage

extension Image {
    /// Fix image orientaton to protrait up
    public func fixedOrientation() -> UIImage? {
        guard imageOrientation != UIImage.Orientation.up else {
            // This is default orientation, don't need to do anything
            return self.copy() as? UIImage
        }

        guard let cgImage = self.cgImage else {
            // CGImage is not available
            return nil
        }

        guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil // Not able to create CGContext
        }

        var transform: CGAffineTransform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }

        // Flip image one more time if needed to, this is to prevent flipped image
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            break
        }

        ctx.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }

        guard let newCGImage = ctx.makeImage() else { return nil }
        return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }

}

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

    public var imageOrientation: Image.Orientation {
        switch self {
        case .up:
            return .up
        case .upMirrored:
            return .upMirrored
        case .down:
            return .down
        case .downMirrored:
            return .downMirrored
        case .left:
            return .left
        case .leftMirrored:
            return .leftMirrored
        case .right:
            return .right
        case .rightMirrored:
            return .rightMirrored
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
