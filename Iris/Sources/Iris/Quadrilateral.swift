import AVFoundation
import CoreGraphics

/// A quadrilateral.
public protocol Quadrilateral {

    /// The quadrilater's top left point.
    var topLeft: CGPoint { get }

    /// The quadrilater's top right point.
    var topRight: CGPoint { get }

    /// The quadrilater's bottom right point.
    var bottomRight: CGPoint { get }

    /// The quadrilater's bottom left point.
    var bottomLeft: CGPoint { get }

}

#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

extension Quadrilateral {

    /// The quadrilateral's path.
    public var path: UIBezierPath {
        let path = UIBezierPath()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.close()
        return path
    }

}

#elseif os(macOS)

import Cocoa

extension Quadrilateral {

    /// The quadrilateral's path.
    public var path: NSBezierPath {
        let path = NSBezierPath()
        path.move(to: topLeft)
        path.line(to: topRight)
        path.line(to: bottomRight)
        path.line(to: bottomLeft)
        path.close()
        return path
    }

}

#endif

extension Quadrilateral {

    /// The quadrilateral's perimeter.
    public var perimeter: CGFloat {
        topLeft.distance(to: topRight) +
            topRight.distance(to: bottomRight) +
            bottomRight.distance(to: bottomLeft) +
            bottomLeft.distance(to: topLeft)
    }

    /// The quadrilateral's area.
    public var area: CGFloat {
        abs((
            (
                topLeft.x * topRight.y +
                topRight.x * bottomRight.y +
                bottomRight.x * bottomLeft.y +
                bottomLeft.x * topLeft.y
            ) - (
                topRight.x * topLeft.y +
                bottomRight.x * topRight.y +
                bottomLeft.x * bottomRight.y +
                topLeft.x * bottomLeft.y
            )
        ) / 2)
    }

    /// Denormalize the rectangle for a given size.
    /// - Parameter size: The size for which to denormalize the rectangle.
    public func denormalize(for size: CGSize) -> Quadrilateral {
        FourSidedFigure(
            topLeft: topLeft.denormalize(for: size),
            topRight: topRight.denormalize(for: size),
            bottomRight: bottomRight.denormalize(for: size),
            bottomLeft: bottomLeft.denormalize(for: size)
        )
    }

    /// Denormalize the rectangle in the coordinate space of a video
    /// preview layer.
    /// - Parameter layer: The video preview whose coordinates space
    /// to denormalized into.
    public func denormalizeInCoordinateSpace(
        of layer: AVCaptureVideoPreviewLayer
    ) -> Quadrilateral {
        FourSidedFigure(
            topLeft: layer.layerPointConverted(
                fromCaptureDevicePoint: CGPoint(x: topLeft.x, y: 1 - topLeft.y)
            ),
            topRight: layer.layerPointConverted(
                fromCaptureDevicePoint: CGPoint(x: topRight.x, y: 1 - topRight.y)
            ),
            bottomRight: layer.layerPointConverted(
                fromCaptureDevicePoint: CGPoint(x: bottomRight.x, y: 1 - bottomRight.y)
            ),
            bottomLeft: layer.layerPointConverted(
                fromCaptureDevicePoint: CGPoint(x: bottomLeft.x, y: 1 - bottomLeft.y)
            )
        )
    }

    /// Rotate the quadrilateral from a right orientation to up orienation.
    public func rotatedFromRightToUp() -> Quadrilateral {
        FourSidedFigure(
            topLeft:  CGPoint(x: 1 - topLeft.y, y: topLeft.x),
            topRight: CGPoint(x: 1 - topRight.y, y: topRight.x),
            bottomRight: CGPoint(x: 1 - bottomRight.y, y: bottomRight.x),
            bottomLeft: CGPoint(x: 1 - bottomLeft.y, y: bottomLeft.x)
        )
    }

}

/// A generic quadrilateral structure.
public struct FourSidedFigure: Quadrilateral {

    public let topLeft: CGPoint

    public let topRight: CGPoint

    public let bottomRight: CGPoint

    public let bottomLeft: CGPoint

    /// Initialize a four sided figure.
    /// - Parameters:
    ///   - topLeft: The figure's top left corner.
    ///   - topRight: The figure's top right corner.
    ///   - bottomRight: The figure's bottom right corner.
    ///   - bottomLeft: The figure's bottom left corner.
    public init(
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }

}
