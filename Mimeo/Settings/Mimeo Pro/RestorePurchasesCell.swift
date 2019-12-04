//
//  RestorePurchasesCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

public protocol RestorePurchasesCellDelegate: AnyObject {

    func restorePurchasesCellDidUpdate(status: MimeoProSubscription.Status)

}

public final class RestorePurchasesCell: SettingCell {

    init(delegate: RestorePurchasesCellDelegate) {
        super.init(
            title: "Restore Purchases",
            shouldDeselectCellOnSelection: true
        ) {
            MimeoProSubscription.restore(delegate.restorePurchasesCellDidUpdate)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
