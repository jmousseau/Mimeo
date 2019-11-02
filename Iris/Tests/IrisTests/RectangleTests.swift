@testable import Iris
import XCTest

final class RectangleTests: XCTestCase {

    func testTopLeft() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        XCTAssertEqual(rect.topLeft, CGPoint(x: 10, y: 20))
    }

    func testBottomRight() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        XCTAssertEqual(rect.bottomRight, CGPoint(x: 40, y: 60))
    }

    func testExpandedByInsets() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        let insets = EdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        XCTAssertEqual(
            rect.expanded(by: insets),
            CGRect(x: 8, y: 19, width: 36, height: 44)
        )
    }

    func testContractedByInsets() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        let insets = EdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        XCTAssertEqual(
            rect.contracted(by: insets),
            CGRect(x: 12, y: 21, width: 24, height: 36)
        )
    }

    func testDenormalizeForSize() {
        let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let size = CGSize(width: 20, height: 10)
        XCTAssertEqual(
            rect.denormalize(for: size),
            CGRect(x: 2, y: 2, width: 6, height: 4)
        )
    }

    func testInCoordinateSpaceOfOrigin() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        let origin = CGPoint(x: 5, y: 10)
        XCTAssertEqual(
            rect.inCoordinateSpace(of: origin),
            CGRect(x: 5, y: 10, width: 30, height: 40)
        )
    }

    func testInNormalizedUIImageCoordinateSpace() {
        let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        XCTAssertEqual(
            rect.inNormalizedUIImageCooridnateSpace(),
            CGRect(x: 0.1, y: 0.4, width: 0.3, height: 0.4)
        )
    }

    func testBorderRectsToRect() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        let outerRect = CGRect(x: 5, y: 10, width: 45, height: 80)
        XCTAssertEqual(
            rect.borderRects(to: outerRect),
            [
                CGRect(x: 5, y: 10, width: 5, height: 80),
                CGRect(x: 10, y: 10, width: 30, height: 10),
                CGRect(x: 40, y: 10, width: 10, height: 80),
                CGRect(x: 10, y: 60, width: 30, height: 30)
            ]
        )
    }

}
