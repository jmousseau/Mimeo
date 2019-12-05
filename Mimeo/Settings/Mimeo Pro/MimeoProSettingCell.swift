//
//  MimeoProSettingCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public class MimeoProSettingCell: SettingCell {

    public override init(
        title: String,
        style: UITableViewCell.CellStyle = .default,
        shouldDeselectCellOnSelection: Bool = false,
        action: @escaping () -> Void
    ) {
        super.init(
            title: title,
            style: style,
            shouldDeselectCellOnSelection: shouldDeselectCellOnSelection,
            action: action
        )

        MimeoProSubscription.status { status in
            switch status {
            case .subscribed:
                self.isUserInteractionEnabled = true
                self.contentView.alpha = 1

            case .notSubscribed, .cancelled, .failed:
                self.isUserInteractionEnabled = false
                self.contentView.alpha = 0.4
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
