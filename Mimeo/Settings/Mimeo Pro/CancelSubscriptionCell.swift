//
//  CancelSubscriptionCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class CancelSubscriptionCell: SettingCell {

    init() {
        super.init(
            title: "Cancel Subscription",
            shouldDeselectCellOnSelection: true
        ) {
            UIApplication.shared.open(MimeoProSubscription.settingsURL)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
