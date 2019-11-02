#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias GraphicsImageRenderer = UIGraphicsImageRenderer

#elseif os(macOS)

import Cocoa

/// A graphic image renderer for macOS.
public class MacGraphicsImageRenderer: NSObject {

    /// Does the image renderer alllw image output? Defaults to `true`.
    public var allowsImageOutput: Bool = true

    /// The image renderer's format.
    public let format: GraphicsImageRendererFormat

    /// The image renderer's bounds.
    public let bounds: CGRect

    /// Initialize an image renderer for a given bounds and format.
    /// - Parameter bounds: The renderer's bounds.
    /// - Parameter format: The renderer's format.
    public init(bounds: CGRect, format: GraphicsImageRendererFormat) {
        self.bounds = bounds
        self.format = format
        self.format.bounds = self.bounds

        super.init()
    }

    /// Initialize an image renderer for a given size and format.
    /// - Parameter size: The renderer's size.
    /// - Parameter format: The renderer's format.
    public convenience init(size: CGSize, format: GraphicsImageRendererFormat) {
        self.init(bounds: CGRect(origin: .zero, size: size), format: format)
    }

    /// Initialize an image renderer for a given size.
    /// - Parameter size: The renderer's size.
    public convenience init(size: CGSize) {
        self.init(
            bounds:
            CGRect(origin: .zero, size: size),
            format: GraphicsImageRendererFormat()
        )
    }

    /// Returns an image after applying a given set of actions.
    /// - Parameter actions: The actions performed on the image context.
    public func image(actions: @escaping (GraphicsImageRendererContext) -> Void) -> NSImage {
        NSImage(size: format.bounds.size, flipped: false) { _ in
            let imageContext = GraphicsImageRendererContext()
            imageContext.format = self.format
            actions(imageContext)
            return true
        }
    }

    /// Returns the PNG data representation of the image after applying a given
    /// set of actions.
    /// - Parameter actions: The actions performed on the image context.
    public func pngData(actions: @escaping (GraphicsImageRendererContext) -> Void) -> Data {
        let image = self.image(actions: actions)

        guard let cgImage = image.cgImage else {
            fatalError("Image is not backed by CGImage.")
        }

        let bitmapRepresentation = NSBitmapImageRep(cgImage: cgImage)
        bitmapRepresentation.size = image.size

        guard let data = bitmapRepresentation.representation(
            using: .png,
            properties: [:]
        ) else {
            fatalError("Image could not be tranformed into a PNG.")
        }

        return data
    }

}

public typealias GraphicsImageRenderer = MacGraphicsImageRenderer

#endif
