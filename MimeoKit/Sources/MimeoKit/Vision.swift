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
        return [Double(topLeft.x), Double(topLeft.y)]
    }

}

@available(iOS 13.0, *)
extension Array where Element: VNRecognizedTextObservation {

    /// The recognized text observations concatenated into a single string.
    public func plainText() -> String {
        sortedLeftToRightTopToBottom()
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

            return clusters.sorted(by: { lhs, rhs in
                guard let lhsObservation = lhs.observations.sortedLeftToRightTopToBottom().first,
                    let rhsObservation = rhs.observations.sortedLeftToRightTopToBottom().first else {
                        return true
                }

                return lhsObservation.topLeft.x < rhsObservation.topLeft.x &&
                    lhsObservation.topLeft.y > rhsObservation.topLeft.y
            })
        } catch {
            return []
        }
    }

}
