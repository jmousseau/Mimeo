//
//  CGRect.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreGraphics

extension CGRect {

    /// Scale a rectangle and retain its center.
    /// - Parameter ratio: The ratio by which to scale the rectangle.
    func scaleAndCenter(withRatio ratio: CGFloat) -> CGRect {
        let scale = CGAffineTransform(scaleX: ratio, y: ratio)
        let scaledRect = applying(scale)
        let translation = CGAffineTransform(
            translationX: origin.x * (1 - ratio) + (width - scaledRect.width) / 2,
            y: origin.y * (1 - ratio) + (height - scaledRect.height) / 2
        )
        let translatedRect = scaledRect.applying(translation)
        return translatedRect
    }

}
