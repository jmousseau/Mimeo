@testable import Iris
import Vision
import XCTest

@available(iOS 13.0, macOS 10.15, *)
final class VNRecognizedTextObservationMock: VNRecognizedTextObservation {

    override func topCandidates(_ maxCandidateCount: Int) -> [VNRecognizedText] {
        return [VNRecognizedText()]
    }

}

final class VisionTests: XCTestCase {

    @available(iOS 13.0, macOS 10.15, *)
    func testTopCandidate() {
        XCTAssertNotNil(VNRecognizedTextObservationMock().topCandidate)
    }

    @available(iOS 11.0, macOS 10.15, *)
    func testBoundingBox() {
        let observations = [
            VNRectangleObservation(boundingBox: CGRect(x: 10, y: 50, width: 30, height: 40)),
            VNRectangleObservation(boundingBox: CGRect(x: 60, y: 30, width: 100, height: 10)),
            VNRectangleObservation(boundingBox: CGRect(x: 40, y: 5, width: 50, height: 50)),
            VNRectangleObservation(boundingBox: CGRect(x: 80, y: 100, width: 10, height: 70))
        ]

        XCTAssertEqual(
            observations.boundingBox(),
            CGRect(x: 10, y: 5, width: 150, height: 165)
        )
    }

    @available(iOS 11.0, macOS 10.15, *)
    func testSortedLeftToRightTopToBottom() {
        let observations = [
            VNRectangleObservation(boundingBox: CGRect(x: 2, y: 1, width: 0, height: 0)),
            VNRectangleObservation(boundingBox: CGRect(x: 2, y: 3, width: 0, height: 0)),
            VNRectangleObservation(boundingBox: CGRect(x: 3, y: 2, width: 0, height: 0)),
            VNRectangleObservation(boundingBox: CGRect(x: 1, y: 2, width: 0, height: 0)),
            VNRectangleObservation(boundingBox: CGRect(x: 1, y: 1, width: 0, height: 0)),
            VNRectangleObservation(boundingBox: CGRect(x: 4, y: 1, width: 0, height: 0)),
            VNRectangleObservation(boundingBox: CGRect(x: 2, y: 2, width: 0, height: 0))
        ]

        XCTAssertEqual(
            observations.sortedTopToBottomLeftToRight().map({ observation in
                observation.boundingBox
            }),
            [
                CGRect(x: 2, y: 3, width: 0, height: 0),
                CGRect(x: 1, y: 2, width: 0, height: 0),
                CGRect(x: 2, y: 2, width: 0, height: 0),
                CGRect(x: 3, y: 2, width: 0, height: 0),
                CGRect(x: 1, y: 1, width: 0, height: 0),
                CGRect(x: 2, y: 1, width: 0, height: 0),
                CGRect(x: 4, y: 1, width: 0, height: 0)
            ]
        )
    }
}
