#if targetEnvironment(macCatalyst) || os(iOS)

import Vision

// MARK: - Recognized Text Observation

@available(iOS 13.0, macOS 10.15, *)
extension VNRecognizedTextObservation {

    public var topCandidate: VNRecognizedText? {
        topCandidates(1).first
    }

}

// MARK: - VNRectangleObservation Collection

@available(iOS 11.0, macOS 10.15, *)
extension Collection where Element: VNRectangleObservation {

    /// The bounding box that bounds every bounding box in the collection.
    public func boundingBox() -> CGRect {
        reduce(CGRect(
            x: CGFloat.infinity,
            y: .infinity,
            width: 0,
            height: 0
        )) { boundingBox, observation -> CGRect in
            let topLeftX = [
                boundingBox.topLeft.x,
                observation.boundingBox.topLeft.x
            ].min() ?? 0

            let topLeftY = [
                boundingBox.topLeft.y,
                observation.boundingBox.topLeft.y
            ].min() ?? 0

            let bottomRightX = [
                boundingBox.bottomRight.x,
                observation.boundingBox.bottomRight.x
            ].min() ?? 0

            let bottomRightY = [
                boundingBox.bottomRight.y,
                observation.boundingBox.bottomRight.y
            ].min() ?? 0

            return CGRect(
                x: topLeftX,
                y: topLeftY,
                width: abs(topLeftX - bottomRightX),
                height: abs(topLeftY - bottomRightY)
            )
        }
    }

    /// The rectangle observation's sorted left to right, top to bottom.
    public func sortedLeftToRightTopToBottom() -> [Element] {
        sorted(by: { lhs, rhs in
            lhs.topLeft.x < rhs.topLeft.x && lhs.topLeft.y > rhs.topLeft.y
        })
    }

}

#endif
