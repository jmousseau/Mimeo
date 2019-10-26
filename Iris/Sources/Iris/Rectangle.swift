import CoreGraphics

// MARK: - CGRect

extension CGRect {

    /// The rectangle's top left.
    public var topLeft: CGPoint {
        origin
    }

    /// The rectangle's bottom right.
    public var bottomRight: CGPoint {
        CGPoint(
            x: origin.x + width,
            y: origin.y + height
        )
    }

    /// Expand the rectangle by given insets.
    /// - Parameter insets: The insets by which to expand the rectangle.
    public func expanded(by insets: EdgeInsets) -> CGRect {
        CGRect(
            x: origin.x - insets.left,
            y: origin.y - insets.top,
            width: width + insets.left + insets.right,
            height: height + insets.top + insets.bottom
        )
    }

    /// Contract the rectangle by given insets.
    /// - Parameter insets: The insets by which to contract the rectangle.
    public func contracted(by insets: EdgeInsets) -> CGRect {
        CGRect(
            x: origin.x + insets.left,
            y: origin.y + insets.top,
            width: width - insets.left - insets.right,
            height: height - insets.top - insets.bottom
        )
    }

    /// Denormalize the rectangle for a given size.
    /// - Parameter size: The size for which to denormalize the rectangle.
    public func denormalize(for size: CGSize) -> CGRect {
        CGRect(
            x: origin.x * size.width,
            y: origin.y * size.height,
            width: width * size.width,
            height: height * size.height
        )
    }

    /// Transform the rectangle into a different coordinate space.
    /// - Parameter origin: The origin of the coordinate space for which to
    ///   transform the rectangle.
    public func inCoordinateSpace(of origin: CGPoint) -> CGRect {
        CGRect(
            x: abs(origin.x - origin.x),
            y: abs(origin.y - origin.y),
            width: width,
            height: height
        )
    }

    /// Transform the normalized rectangle from Vision coordinate space to
    /// UIImage coordinate space.
    public func inNormalizedUIImageCooridnateSpace() -> CGRect {
        CGRect(
            x: origin.x,
            y: 1 - origin.y - height,
            width: size.width,
            height: size.height
        )
    }

    /// Construct the border rectangles for a given rectangles.
    ///
    /// ┌──────────┬──────────────────┬──────────┐
    /// │          │                  │          │
    /// │          │  Border Rect 1   │          ◀── rect
    /// │          │                  │          │
    /// │          ├──────────────────┤          │
    /// │  Border  │                  │  Border  │
    /// │  Rect 0  │       self       │  Rect 2  │
    /// │          │                  │          │
    /// │          ├──────────────────┤          │
    /// │          │                  │          │
    /// │          │  Border Rect 3   │          │
    /// │          │                  │          │
    /// └──────────┴──────────────────┴──────────┘
    ///
    /// - Parameter rect: The rectangle for which to construct the border
    ///   rectangles.
    public func borderRects(to rect: CGRect) -> [CGRect] {
        [
            CGRect(
                x: origin.x,
                y: origin.y,
                width: abs(origin.x - rect.origin.x),
                height: height
            ),
            CGRect(
                x: rect.origin.x,
                y: origin.y,
                width: rect.width,
                height: abs(origin.y - rect.origin.y)
            ),
            CGRect(
                x: rect.origin.x + rect.width,
                y: origin.y,
                width: abs((rect.origin.x + rect.width) - (origin.x + width)),
                height: height
            ),
            CGRect(
                x: rect.origin.x,
                y: rect.origin.y + rect.height,
                width: rect.width,
                height: abs((rect.origin.y + rect.height) - (origin.y + height))
            )
        ]
    }

}
