import Vision

// MARK: - Recognized Text Observation

@available(iOS 13.0, macOS 10.15, *)
extension VNRecognizedTextObservation {

    /// The top most candidate, if one exists.
    public var topCandidate: VNRecognizedText? {
        topCandidates(1).first
    }

}

// MARK: - VNRectangleObservation Collection

@available(iOS 11.0, macOS 10.15, *)
extension Collection where Element: VNRectangleObservation {

    /// The bounding box that bounds every bounding box in the collection.
    public func boundingBox() -> CGRect {
        guard let initialBoundingBox = first?.boundingBox else {
            return .zero
        }

        return reduce(initialBoundingBox) { boundingBox, observation -> CGRect in
            let topLeftX = [
                boundingBox.topLeft.x,
                observation.boundingBox.topLeft.x
            ].min()!

            let topLeftY = [
                boundingBox.topLeft.y,
                observation.boundingBox.topLeft.y
            ].min()!

            let bottomRightX = [
                boundingBox.bottomRight.x,
                observation.boundingBox.bottomRight.x
            ].max()!

            let bottomRightY = [
                boundingBox.bottomRight.y,
                observation.boundingBox.bottomRight.y
            ].max()!

            return CGRect(
                x: topLeftX,
                y: topLeftY,
                width: abs(topLeftX - bottomRightX),
                height: abs(topLeftY - bottomRightY)
            )
        }
    }

    /// The rectangle observation's sorted top to bottom, left to right.
    public func sortedTopToBottomLeftToRight() -> [Element] {
        sorted(by: { lhs, rhs in
            if lhs.topLeft.y == rhs.topLeft.y {
                return lhs.topLeft.x < rhs.topLeft.x
            }

            // Vision origin is the bottom left of the image.
            return lhs.topLeft.y > rhs.topLeft.y
        })
    }

}
