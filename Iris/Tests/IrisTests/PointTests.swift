@testable import Iris
import XCTest

final class PointTests: XCTestCase {

    func testDistance() {
        XCTAssertEqual(CGPoint.zero.distance(to: CGPoint(x: 3, y: 4)), 5)
        XCTAssertEqual(CGPoint.zero.distance(to: CGPoint(x: -3, y: 4)), 5)
        XCTAssertEqual(CGPoint.zero.distance(to: CGPoint(x: 3, y: -4)), 5)
        XCTAssertEqual(CGPoint.zero.distance(to: CGPoint(x: -3, y: -4)), 5)

        XCTAssertEqual(CGPoint(x: 1, y: 2).distance(to: CGPoint(x: 4, y: 6)), 5)
    }

    func testNormalizedFor() {
        XCTAssertEqual(
            CGPoint(x: 50, y: 60).normalized(for: CGSize(width: 100, height: 800)),
            CGPoint(x: 0.5, y: 0.075)
        )
    }

    func testDenormalizeFor() {
        XCTAssertEqual(
            CGPoint.zero.denormalize(for: CGSize(width: 1, height: 1)),
            .zero
        )

        XCTAssertEqual(
            CGPoint(x: 0.5, y: 0.1).denormalize(for: CGSize(width: 10, height: 100)),
            CGPoint(x: 5, y: 10)
        )
    }

}
