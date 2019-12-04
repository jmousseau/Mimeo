//
//  SubscribeCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

public protocol SubscribeCellDelegate: AnyObject {

    func subscribeCellDidUpdate(status: MimeoProSubscription.Status)

}

public final class SubscribeCell: SettingCell {

    init(delegate: SubscribeCellDelegate) {
        super.init(
            title: "Subscribe",
            style: .value1,
            shouldDeselectCellOnSelection: true
        ) {
            MimeoProSubscription.subscribe(delegate.subscribeCellDidUpdate)
        }

        MimeoProSubscription.annualPackage { annualPackage in
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = annualPackage.product.priceLocale

            guard let priceString = formatter.string(from: annualPackage.product.price) else {
                return
            }

            self.detailTextLabel?.text = "\(priceString) per year"
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
