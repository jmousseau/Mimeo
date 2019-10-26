import UIKit

// MARK: - UIColor

extension UIColor {

    /// The color's red, green, blue, and alpha components.
    public var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }

    /// The color's hue, saturation, brightness, and alpha components.
    public var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return (hue, saturation, brightness, alpha)
    }

}

// MARK: - UIColor Collection

extension Collection where Element == UIColor {

    /// The average colors.
    public func average() -> UIColor? {
        guard count > 0 else {
            return nil
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        for color in self {
            let rgba = color.rgba
            red += rgba.red
            green += rgba.green
            blue += rgba.blue
            alpha += rgba.alpha
        }

        return UIColor(
            red: red / CGFloat(count),
            green: green / CGFloat(count),
            blue: blue / CGFloat(count),
            alpha: alpha / CGFloat(count)
        )
    }

}
