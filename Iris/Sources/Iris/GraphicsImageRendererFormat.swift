import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias GraphicsImageRendererFormat = UIGraphicsImageRendererFormat

#elseif os(macOS)

import Cocoa

public class MacGraphicsImageRendererFormat: NSObject {

    public var opaque: Bool = false

    public var prefersExtendedRange: Bool = false

    public var scale: CGFloat = 2.0

    public var bounds: CGRect = .zero

}

public typealias GraphicsImageRendererFormat = MacGraphicsImageRendererFormat

#endif
