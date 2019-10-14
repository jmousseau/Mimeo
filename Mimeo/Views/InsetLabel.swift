//
//  InsetLabel.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/13/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

/// An inset label.
public final class InsetLabel: UILabel {

    /// The label's content insets. Defaults to zero.
    public var contentInsets: UIEdgeInsets = .zero

    public override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    public override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

}
