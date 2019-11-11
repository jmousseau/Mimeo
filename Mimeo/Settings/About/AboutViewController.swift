//
//  AboutViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class AboutViewController: StaticTableViewController {

    public init() {
        super.init(style: .grouped)

        sections = [
            Section(
                cells: [
                    ApplicationVersionCell(),
                    ApplicationBuildNumberCell()
                ]
            )
        ]

        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
