//
//  VNRecgonizedTextObservation.swift
//  MimeoKit
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Vision

@available(iOS 11.0, *)
extension VNRectangleObservation: Clusterable {

    /// The rectangle observation's features used for algorithms such as
    /// clustering.
    public func clusterFeatures() -> [Double] {
        [Double(boundingBox.center.x * 0.5), Double(boundingBox.center.y * 2)]
    }

}

@available(iOS 13.0, *)
extension Array where Element: VNRecognizedTextObservation {

    /// The recognized text observations concatenated into a single string.
    public func plainText() -> String {
        sortedTopToBottomLeftToRight()
            .compactMap({ observation in
                observation.topCandidate?.string
            })
            .joined(separator: " ")
    }

    /// The recognized text observations grouped and then concatenated into a
    /// single string.
    public func groupedText() -> [String] {
        clustered()
            .map({ cluster in
                cluster.observations
                    .compactMap({ observation in
                        observation.topCandidate?.string
                    })
                    .joined(separator: " ")
            })
    }

    /// The recognized text observations clustered by bounding box location and
    /// sorted from left to right, top to bottom.
    public func clustered() -> [Cluster<VNRecognizedTextObservation>] {
        do {
            let cluster = try Cluster<VNRecognizedTextObservation>(observations: self)
            let (clusters, _) = cluster.cluster(using: .kMeansElbow(
                threshold: 0.2,
                maximumNumberOfGroups: 3
            ))

            // TODO: [Performance] The bounding box can be cached for each
            // cluster.
            return clusters.sorted(by: { lhs, rhs in
                let lhsBoundingBox = lhs.observations.boundingBox()
                let rhsBoundingBox = rhs.observations.boundingBox()
                let lhsCenter = lhsBoundingBox.center
                let rhsCenter = rhsBoundingBox.center

                if lhsCenter.y == rhsCenter.y {
                    return lhsCenter.x < rhsCenter.x
                }

                // Vision origin is the bottom left of the image.
                return lhsCenter.y > rhsCenter.y

            })
        } catch {
            return []
        }
    }

}
