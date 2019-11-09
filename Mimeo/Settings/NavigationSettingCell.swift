//
//  NavigationSettingCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/8/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public class NavigationSettingCell: UITableViewCell {

    public static let identifier = "navigation-setting-cell"

    public let action: () -> Void

    public let shouldDeselectCellOnSelection: Bool

    public init(
        title: String,
        style: UITableViewCell.CellStyle = .default,
        shouldDeselectCellOnSelection: Bool = false,
        action: @escaping () -> Void
    ) {
        self.action = action
        self.shouldDeselectCellOnSelection = shouldDeselectCellOnSelection

        super.init(style: style, reuseIdentifier: Self.identifier)

        textLabel?.text = title
        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
