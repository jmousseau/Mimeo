import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias GraphicsImageRendererContext = UIGraphicsImageRendererContext

#elseif os(macOS)

import Cocoa

public class MacGraphicsImageRendererContext: NSObject {

    public var format: GraphicsImageRendererFormat

    public var cgContext: CGContext {
        guard let context = NSGraphicsContext.current?.cgContext else {
            fatalError("Unavailable cgContext while drawing")
        }
        return context
    }

    public func clip(to rect: CGRect) {
        cgContext.clip(to: rect)
    }

    public func fill(_ rect: CGRect) {
        cgContext.fill(rect)
    }

    public func fill(_ rect: CGRect, blendMode: CGBlendMode) {
        NSGraphicsContext.saveGraphicsState()
        cgContext.setBlendMode(blendMode)
        cgContext.fill(rect)
        NSGraphicsContext.restoreGraphicsState()
    }

    public func stroke(_ rect: CGRect) {
        cgContext.stroke(rect)
    }

    public func stroke(_ rect: CGRect, blendMode: CGBlendMode) {
        NSGraphicsContext.saveGraphicsState()
        cgContext.setBlendMode(blendMode)
        cgContext.stroke(rect)
        NSGraphicsContext.restoreGraphicsState()
    }

    public override init() {
        self.format = GraphicsImageRendererFormat()
        super.init()
    }

    public var currentImage: NSImage {
        guard let cgImage = cgContext.makeImage() else {
            fatalError("Cannot retrieve cgImage from current context")
        }

        return NSImage(cgImage: cgImage, size: format.bounds.size)
    }

}

public typealias GraphicsImageRendererContext = MacGraphicsImageRendererContext

#endif
