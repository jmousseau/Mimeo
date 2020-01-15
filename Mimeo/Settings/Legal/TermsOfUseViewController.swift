//
//  TermsOfUseViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 1/14/20.
//  Copyright © 2020 Jack Mousseau. All rights reserved.
//

import Foundation

/// A privacy policy view controller.
public final class TermsOfUseViewController: InAppWebViewController {

    /// Initialize a privacy policy view controller.
    public init() {
        super.init(
            url: "https://jmousseau.com/mimeo/in-app-terms-of-use.html"
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
