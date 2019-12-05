//
//  UITableView.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/7/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

extension UITableView {

    /// Deselect the table view's selected row, if applicable.
    /// - Parameter animated: Should the deselection be animated? Defaults to
    ///   true.
    public func deselectRowForSelectedIndexPath(animated: Bool = true) {
        if let selectedIndexPath = indexPathForSelectedRow {
            deselectRow(at: selectedIndexPath, animated: animated)
        }
    }

}
