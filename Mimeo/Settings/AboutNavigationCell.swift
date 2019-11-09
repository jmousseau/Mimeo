//
//  AboutNavigationCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class AboutNavigationCell: NavigationSettingCell {

    public init(presenter: UIViewController) {
        let title = "About"

        super.init(title: title, action: {
            let aboutViewController = AboutViewController()
            aboutViewController.view.tintColor = .mimeoYellow
            aboutViewController.navigationItem.title = title

            presenter.navigationController?.pushViewController(
                aboutViewController,
                animated: true
            )
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
