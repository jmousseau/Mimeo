@testable import Iris
import XCTest

final class ColorTests: XCTestCase {

    func testRGBA() {
        let color: Color = UIColor(
            red: 0.5,
            green: 0.2,
            blue: 0.3,
            alpha: 0.4
        )

        XCTAssertEqual(color.rgba.red, 0.5)
        XCTAssertEqual(color.rgba.green, 0.2)
        XCTAssertEqual(color.rgba.blue, 0.3)
        XCTAssertEqual(color.rgba.alpha, 0.4)
    }

    func testHSBA() {
        let color: Color = UIColor(
            hue: 0.5,
            saturation: 0.2,
            brightness: 0.3,
            alpha: 0.4
        )

        XCTAssertEqual(color.hsba.hue, 0.5)
        XCTAssertEqual(color.hsba.saturation, 0.2)
        XCTAssertEqual(color.hsba.brightness, 0.3)
        XCTAssertEqual(color.hsba.alpha, 0.4)
    }

    func testAverage() {
        XCTAssertNil([Color]().average())

        let colors: [Color] = [.red, .green, .blue, .black]
        XCTAssertNotNil(colors.average())
        XCTAssertEqual(colors.average()!.rgba.red, 0.25)
        XCTAssertEqual(colors.average()!.rgba.green, 0.25)
        XCTAssertEqual(colors.average()!.rgba.blue, 0.25)
        XCTAssertEqual(colors.average()!.rgba.alpha, 1)
    }

}
