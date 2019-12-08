//
//  UITextView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/8/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

extension UITextView {


    /// Highlight a given string in the text view.
    /// - Parameters:
    ///   - string: The string which to highlight.
    ///   - highlightFont: The highlighted text font.
    ///   - highlightColor: The highlighted text color.
    ///   - hightlightMultipleStringLength: The minimum string length required
    ///     for multiple highlights in the same string. Defaults to one.
    public func highlight(
        string: String,
        highlightFont: UIFont,
        highlightColor: UIColor,
        hightlightMultipleStringLength: Int = 1
    ) {
        guard !string.isEmpty else {
            return
        }

        guard let expression = try? NSRegularExpression(
            pattern: NSRegularExpression.escapedPattern(for: string),
            options: .caseInsensitive
        ) else {
            return
        }

        let mutableAttributedText = NSMutableAttributedString(
            attributedString: attributedText
        )

        for (matchIndex, match) in expression.matches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..<text.endIndex, in: text)
        ).enumerated() {
            if matchIndex > 0 && string.count <= hightlightMultipleStringLength {
                continue
            }

            for rangeIndex in 0..<match.numberOfRanges {
                mutableAttributedText.addAttributes([
                    .font: highlightFont,
                    .foregroundColor: highlightColor
                ], range: match.range(at: rangeIndex))
            }
        }

        attributedText = mutableAttributedText
    }

}
