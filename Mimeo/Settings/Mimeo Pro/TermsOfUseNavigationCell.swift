//
//  TermsOfUseNavigationCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 1/14/20.
//  Copyright © 2020 Jack Mousseau. All rights reserved.
//

import UIKit

public final class TermsOfUseNavigationCell: SettingCell {

    public init(presenter: UIViewController) {
        super.init(
            title: "Terms of Use",
            action: {
                let termsOfUseViewController = TermsOfUseViewController()
                termsOfUseViewController.view.tintColor = .mimeoYellow
                termsOfUseViewController.navigationItem.title = "Terms of Use"
                termsOfUseViewController.navigationItem.largeTitleDisplayMode = .never
                presenter.navigationController?.pushViewController(
                    termsOfUseViewController,
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
