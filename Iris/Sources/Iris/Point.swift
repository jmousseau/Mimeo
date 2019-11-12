import CoreGraphics

extension CGPoint {

    /// Normalize the point for a given size.
    /// - Parameter size: The size for which to normalize the point.
    public func normalized(for size: CGSize) -> CGPoint {
        CGPoint(
            x: x / size.width,
            y: y / size.height
        )
    }

}
