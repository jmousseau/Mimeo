//
//  ApplicationVersionCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class ApplicationVersionCell: UITableViewCell {

    public static let identifier = "application-version-cell"

    public init() {
        super.init(style: .value1, reuseIdentifier: Self.identifier)

        selectionStyle = .none

        textLabel?.text = "Version"
        detailTextLabel?.text = Bundle.main.applicationVersion
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
