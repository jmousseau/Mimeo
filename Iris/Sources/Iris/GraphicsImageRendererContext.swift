#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias GraphicsImageRendererContext = UIGraphicsImageRendererContext

#elseif os(macOS)

import Cocoa

/// An image renderer context for macOS.
public class MacGraphicsImageRendererContext: NSObject {

    /// The context's core graphics context.
    public var cgContext: CGContext {
        guard let context = NSGraphicsContext.current?.cgContext else {
            fatalError("Unavailable cgContext while drawing")
        }

        return context
    }

    /// The context's curent image.
    public var currentImage: NSImage {
        guard let cgImage = cgContext.makeImage() else {
            fatalError("Cannot retrieve cgImage from current context")
        }

        return NSImage(cgImage: cgImage, size: format.bounds.size)
    }

    /// The context's format.
    public var format: GraphicsImageRendererFormat

    /// Initialize a context with the default render format.
    public override init() {
        self.format = GraphicsImageRendererFormat()
        super.init()
    }

    /// Clip the context to a given rectangle.
    /// - Parameter rect: The rectangle with which to clip the context.
    public func clip(to rect: CGRect) {
        cgContext.clip(to: rect)
    }

    /// Fill the context with a given rectangle.
    /// - Parameter rect: The rectangle with which to fill the context.
    public func fill(_ rect: CGRect) {
        cgContext.fill(rect)
    }

    /// Fill the context with a given rectangle and blend mode.
    /// - Parameter rect: The rectangle with which to the fill the context.
    /// - Parameter blendMode: The blend mode set before filling the context.
    public func fill(_ rect: CGRect, blendMode: CGBlendMode) {
        NSGraphicsContext.saveGraphicsState()
        cgContext.setBlendMode(blendMode)
        cgContext.fill(rect)
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Stroke the context with a given rectangle.
    /// - Parameter rect: The rectangle with which to stroke the context.
    public func stroke(_ rect: CGRect) {
        cgContext.stroke(rect)
    }

    /// Stroke the context with a given rectangle and blend mode.
    /// - Parameter rect: The rectangle with which to stroke the context.
    /// - Parameter blendMode: The blend mode set before stroking the context.
    public func stroke(_ rect: CGRect, blendMode: CGBlendMode) {
        NSGraphicsContext.saveGraphicsState()
        cgContext.setBlendMode(blendMode)
        cgContext.stroke(rect)
        NSGraphicsContext.restoreGraphicsState()
    }

}

public typealias GraphicsImageRendererContext = MacGraphicsImageRendererContext

#endif
