//
//  MimeoProNavigationCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class MimeoProNavigationCell: SettingCell {

    public init(presenter: UIViewController) {
        super.init(
            title: "Mimeo Copy Pro",
            action: {
                let mimeoProViewController = MimeoProViewController()
                mimeoProViewController.view.tintColor = .mimeoYellow
                mimeoProViewController.navigationItem.title = "Mimeo Copy Pro"
                presenter.navigationController?.pushViewController(
                    mimeoProViewController,
                    animated: true
                )
            }
        )

        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
