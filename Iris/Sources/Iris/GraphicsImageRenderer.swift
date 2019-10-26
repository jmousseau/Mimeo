import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias GraphicsImageRenderer = UIGraphicsImageRenderer

#elseif os(macOS)

import Cocoa

public class MacGraphicsImageRenderer: NSObject {

    public class func context(with format: GraphicsImageRendererFormat) -> CGContext? {
        fatalError("Not implemented")
    }

    public class func prepare(_ context: CGContext, with: GraphicsImageRendererContext) {
        fatalError("Not implemented")
    }

    public class func rendererContextClass() {
        fatalError("Not implemented")
    }

    public var allowsImageOutput: Bool = true

    public let format: GraphicsImageRendererFormat

    public let bounds: CGRect

    public init(bounds: CGRect, format: GraphicsImageRendererFormat) {
        (self.bounds, self.format) = (bounds, format)
        self.format.bounds = self.bounds
        super.init()
    }

    public convenience init(size: CGSize, format: GraphicsImageRendererFormat) {
        self.init(bounds: CGRect(origin: .zero, size: size), format: format)
    }

    public convenience init(size: CGSize) {
        self.init(bounds: CGRect(origin: .zero, size: size), format: GraphicsImageRendererFormat())
    }

    public func image(actions: @escaping (GraphicsImageRendererContext) -> Void) -> NSImage {
        let image = NSImage(size: format.bounds.size, flipped: false) {
            (drawRect: NSRect) -> Bool in

            let imageContext = GraphicsImageRendererContext()
            imageContext.format = self.format
            actions(imageContext)

            return true
        }
        return image
    }

    public func pngData(actions: @escaping (GraphicsImageRendererContext) -> Void) -> Data {
        let image = self.image(actions: actions)
        var imageRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
            else { fatalError("Could not construct PNG data from drawing request") }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size
        guard let data = bitmapRep.representation(using: .png, properties: [:])
            else { fatalError("Could not retrieve data from drawing request") }
        return data
    }

    public func jpegData(withCompressionQuality compressionQuality: CGFloat, actions: @escaping (GraphicsImageRendererContext) -> Void) -> Data {
        let image = self.image(actions: actions)
        var imageRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
            else { fatalError("Could not construct PNG data from drawing request") }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size
        guard let data = bitmapRep.representation(using: .jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: compressionQuality])
            else { fatalError("Could not retrieve data from drawing request") }
        return data
    }

    public func runDrawingActions(_ drawingActions: (GraphicsImageRendererContext) -> Void, completionActions: ((GraphicsImageRendererContext) -> Void)? = nil) throws {
        fatalError("Not implemented")
    }
}

public typealias GraphicsImageRenderer = MacGraphicsImageRenderer

#endif
