//
//  VNRecgonizedTextObservation.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/6/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Vision

extension VNRecognizedTextObservation {

    public var topCandidate: VNRecognizedText? {
        topCandidates(1).first
    }

}

extension VNRectangleObservation: Clusterable {

    /// The rectangle observation's features used for algorithms such as
    /// clustering.
    public func clusterFeatures() -> [Double] {
        return [Double(topLeft.x), Double(topLeft.y)]
    }

}

extension Collection where Element: VNRectangleObservation {

    /// The rectangle observation's sorted left to right, top to bottom.
    public func sortedLeftToRightTopToBottom() -> [Element] {
        sorted(by: { lhs, rhs in
            lhs.topLeft.x < rhs.topLeft.x && lhs.topLeft.y > rhs.topLeft.y
        })
    }

}

extension Array where Element: VNRecognizedTextObservation {

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
