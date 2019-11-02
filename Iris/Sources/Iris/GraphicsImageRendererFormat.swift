#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias GraphicsImageRendererFormat = UIGraphicsImageRendererFormat

#elseif os(macOS)

import Cocoa

/// An image renderer format for macOS.
public class MacGraphicsImageRendererFormat: NSObject {

    /// Is the image renderer format opaque? Defaults to `false`.
    public var opaque: Bool = false

    /// Does the image renderer format prefer extended range? Defaults to
    /// `false`.
    public var prefersExtendedRange: Bool = false

    /// The image renderer's scale. Defaults to 2.
    public var scale: CGFloat = 2.0

    /// The image renderer's bounds. Defaults to the zero rect.
    public var bounds: CGRect = .zero

}

public typealias GraphicsImageRendererFormat = MacGraphicsImageRendererFormat

#endif
