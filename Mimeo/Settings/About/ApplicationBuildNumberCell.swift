//
//  ApplicationBuildNumberCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class ApplicationBuildNumberCell: UITableViewCell {

    public static let identifier = "application-build-number-cell"

    public init() {
        super.init(style: .value1, reuseIdentifier: Self.identifier)

        selectionStyle = .none

        textLabel?.text = "Build Number"
        detailTextLabel?.text = Bundle.main.applicationBuildNumber
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
