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

extension Collection where Element: VNRectangleObservation {

    /// The rectangle observation's sorted left to right, top to bottom.
    public func sortedLeftToRightTopToBottom() -> [Element] {
        sorted(by: { lhs, rhs in
            lhs.topLeft.x < rhs.topLeft.x && lhs.topLeft.y > rhs.topLeft.y
        })
    }
}
