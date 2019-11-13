import CoreGraphics

extension CGPoint {

    /// The Euclidean distance to another point.
    /// - Parameter point: The point to measure the distance to.
    public func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
    }

    /// Normalize the point for a given size.
    /// - Parameter size: The size for which to normalize the point.
    public func normalized(for size: CGSize) -> CGPoint {
        CGPoint(
            x: x / size.width,
            y: y / size.height
        )
    }

    /// Denormalize the point for a given size.
    /// - Parameter size: The size for which to denormalize the point.
    public func denormalize(for size: CGSize) -> CGPoint {
        CGPoint(
            x: x * size.width,
            y: y * size.height
        )
    }

}
