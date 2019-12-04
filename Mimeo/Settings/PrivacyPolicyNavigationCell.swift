//
//  PrivacyPolicyNavigationCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/24/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class PrivacyPolicyNavigationCell: SettingCell {

    public init(presenter: UIViewController) {
        super.init(
            title: "Privacy Policy",
            action: {
                let privacyPolicyViewController = PrivacyPolicyViewController()
                privacyPolicyViewController.view.tintColor = .mimeoYellow
                privacyPolicyViewController.navigationItem.title = "Privacy Policy"
                privacyPolicyViewController.navigationItem.largeTitleDisplayMode = .never
                presenter.navigationController?.pushViewController(
                    privacyPolicyViewController,
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
