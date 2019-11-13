import AVFoundation
@testable import Iris
import XCTest

final class QuadrilateralTests: XCTestCase {

    func testPath() {
        let quadrilateral = FourSidedFigure(
            topLeft: CGPoint(x: 1, y: 2),
            topRight: CGPoint(x: 2, y: 3),
            bottomRight: CGPoint(x: 3, y: 4),
            bottomLeft: CGPoint(x: 4, y: 5)
        )

        let path = quadrilateral.path
        XCTAssertTrue(path.cgPath.contains(quadrilateral.topLeft))
        XCTAssertTrue(path.cgPath.contains(quadrilateral.topRight))
        XCTAssertTrue(path.cgPath.contains(quadrilateral.bottomRight))
        XCTAssertTrue(path.cgPath.contains(quadrilateral.bottomLeft))
    }

    func testParimeter() {
        let rectangle = FourSidedFigure(
            topLeft: CGPoint(x: 2, y: 2),
            topRight: CGPoint(x: 12, y: 2),
            bottomRight: CGPoint(x: 12, y: 4),
            bottomLeft: CGPoint(x: 2, y: 4)
        )

        XCTAssertEqual(rectangle.perimeter, 24)

        let rhombus = FourSidedFigure(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: 4, y: 3),
            bottomRight: CGPoint(x: 4, y: 7),
            bottomLeft: CGPoint(x: 0, y: 4)
        )

        XCTAssertEqual(rhombus.perimeter, 18)

        let quadrilateral = FourSidedFigure(
            topLeft: CGPoint(x: 0, y: 1),
            topRight: CGPoint(x: 1, y: 5),
            bottomRight: CGPoint(x: 3, y: 6),
            bottomLeft: CGPoint(x: 4, y: 5)
        )

        XCTAssertEqual(floor(quadrilateral.perimeter * 10000), 134302)
    }

    func testArea() {
        let rectangle = FourSidedFigure(
            topLeft: CGPoint(x: 2, y: 2),
            topRight: CGPoint(x: 12, y: 2),
            bottomRight: CGPoint(x: 12, y: 4),
            bottomLeft: CGPoint(x: 2, y: 4)
        )

        XCTAssertEqual(rectangle.area, 20)

        let rhombus = FourSidedFigure(
            topLeft: CGPoint(x: 0, y: 0),
            topRight: CGPoint(x: 4, y: 3),
            bottomRight: CGPoint(x: 4, y: 7),
            bottomLeft: CGPoint(x: 0, y: 4)
        )

        XCTAssertEqual(rhombus.area, 16)

        let quadrilateral = FourSidedFigure(
            topLeft: CGPoint(x: 0, y: 1),
            topRight: CGPoint(x: 1, y: 5),
            bottomRight: CGPoint(x: 3, y: 6),
            bottomLeft: CGPoint(x: 4, y: 5)
        )

        XCTAssertEqual(quadrilateral.area, 7.5)
    }

    func testDenormaizedForSize() {
        let normalizedQuadrilateral = FourSidedFigure(
            topLeft: CGPoint(x: 0.1, y: 0.2),
            topRight: CGPoint(x: 0.2, y: 0.3),
            bottomRight: CGPoint(x: 0.4, y: 0.5),
            bottomLeft: CGPoint(x: 0.6, y: 0.7)
        )

        let denormalizedQuadrilateral = normalizedQuadrilateral.denormalize(
            for: CGSize(width: 10, height: 100)
        )

        XCTAssertEqual(
            denormalizedQuadrilateral.topLeft,
            CGPoint(x: 1, y: 20)
        )

        XCTAssertEqual(
            denormalizedQuadrilateral.topRight,
            CGPoint(x: 2, y: 30)
        )

        XCTAssertEqual(
            denormalizedQuadrilateral.bottomRight,
            CGPoint(x: 4, y: 50)
        )

        XCTAssertEqual(
            denormalizedQuadrilateral.bottomLeft,
            CGPoint(x: 6, y: 70)
        )
    }

    func testDenormalizeInCoorinateSpaceOfLayer() {
        let layer = AVCaptureVideoPreviewLayer()

        let normalizedQuadrilateral = FourSidedFigure(
            topLeft: CGPoint(x: 0.1, y: 0.2),
            topRight: CGPoint(x: 0.2, y: 0.3),
            bottomRight: CGPoint(x: 0.4, y: 0.5),
            bottomLeft: CGPoint(x: 0.6, y: 0.7)
        )

        let denormalizedQuadrilateral = normalizedQuadrilateral.denormalizeInCoordinateSpace(
            of: layer
        )

        XCTAssertEqual(
            denormalizedQuadrilateral.topLeft,
            CGPoint(x: 0.1, y: 0.8)
        )

        XCTAssertEqual(
            denormalizedQuadrilateral.topRight,
            CGPoint(x: 0.2, y: 0.7)
        )

        XCTAssertEqual(
            denormalizedQuadrilateral.bottomRight,
            CGPoint(x: 0.4, y: 0.5)
        )

        XCTAssertEqual(denormalizedQuadrilateral.bottomLeft.x, 0.6)
        XCTAssertEqual(floor(denormalizedQuadrilateral.bottomLeft.y * 10), 3)
    }

}
