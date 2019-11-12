@testable import Iris
import XCTest

final class PointTests: XCTestCase {

    func testNormalizedFor() {
        XCTAssertEqual(
            CGPoint(x: 50, y: 60).normalized(for: CGSize(width: 100, height: 800)),
            CGPoint(x: 0.5, y: 0.075)
        )
    }

}
