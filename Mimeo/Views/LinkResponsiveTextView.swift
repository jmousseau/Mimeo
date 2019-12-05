//
//  LinkResponsiveTextView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/7/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//
//  Source: https://gist.github.com/saoudrizwan/986714d5a093f481fb3f4f6589418ea6

import UIKit

public final class LinkResponsiveTextView: UITextView {

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        delaysContentTouches = false

        isScrollEnabled = false
        isEditable = false
        isUserInteractionEnabled = true
        isSelectable = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func hitTest(
        _ point: CGPoint,
        with event: UIEvent?
    ) -> UIView? {
        var location = point
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top

        let characterIndex = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        guard characterIndex < textStorage.length else {
            return nil
        }

        guard textStorage.attribute(
            .link,
            at: characterIndex,
            effectiveRange: nil
        ) != nil else {
            return nil
        }

        return self
    }

}
