//
//  UIBarButtonItem.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

extension UIBarButtonItem {

    /// Make a done bar button item.
    /// - Parameters:
    ///   - target: The button's target.
    ///   - action: The button's action.
    public static func makeDoneButton(
        target: Any,
        action: Selector
    ) -> UIBarButtonItem {
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: target,
            action: action
        )
        doneButton.tintColor = .mimeoYellow
        return doneButton
    }

}
