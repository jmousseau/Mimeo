//
//  PrivacyPolicyViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/24/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit
import WebKit

/// A privacy policy view controller.
public final class PrivacyPolicyViewController: InAppWebViewController {

    /// The privacy policy view controller's privacy policy web view.
    private let privacyPolicyWebView = WKWebView(frame: .zero)

    /// Initialize a privacy policy view controller.
    public init() {
        super.init(
            url: "https://jmousseau.com/mimeo/in-app-privacy-policy.html"
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
