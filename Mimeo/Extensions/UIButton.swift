//
//  UIButton.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/12/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

extension UIButton {

    /// Set the button's content edge insets and title padding.
    /// - Parameters:
    ///   - contentEdgeInsets: The button's content edge insets.
    ///   - titlePadding: The button's title padding.
    public func setContentEdgeInsets(
        _ contentEdgeInsets: UIEdgeInsets,
        withTitlePadding titlePadding: CGFloat
    ) {
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentEdgeInsets.top,
            left: contentEdgeInsets.left,
            bottom: contentEdgeInsets.bottom,
            right: contentEdgeInsets.right + titlePadding
        )

        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: titlePadding,
            bottom: 0,
            right: -titlePadding
        )
    }

}

