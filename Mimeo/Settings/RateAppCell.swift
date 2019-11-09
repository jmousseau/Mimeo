//
//  RateAppCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/8/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import StoreKit

public final class RateAppCell: NavigationSettingCell {

    public init() {
        super.init(
            title: "Rate \(Bundle.main.applicationDisplayName)",
            shouldDeselectCellOnSelection: true
        ) {
            SKStoreReviewController.requestReview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
