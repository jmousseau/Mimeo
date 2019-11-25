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
public class PrivacyPolicyViewController: UIViewController {

    /// The privacy policy view controller's privacy policy web view.
    private let privacyPolicyWebView = WKWebView(frame: .zero)

    /// Initialize a privacy policy view controller.
    public init() {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .systemBackground

        let privacyPolicyURL = URL(
            string: "https://jmousseau.com/mimeo/in-app-privacy-policy.html"
        )!

        privacyPolicyWebView.load(URLRequest(url: privacyPolicyURL))
        privacyPolicyWebView.navigationDelegate = self
        privacyPolicyWebView.isOpaque = false
        privacyPolicyWebView.backgroundColor = .clear
        privacyPolicyWebView.scrollView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Web View Navigation

extension PrivacyPolicyViewController: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        guard privacyPolicyWebView.superview == nil else {
            return
        }

        addWebview()
    }

}

// MARK: - View Layout

extension PrivacyPolicyViewController {

    private func addWebview() {
        view.addSubview(privacyPolicyWebView)

        privacyPolicyWebView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: privacyPolicyWebView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: privacyPolicyWebView.trailingAnchor),
            view.topAnchor.constraint(equalTo: privacyPolicyWebView.topAnchor),
            view.bottomAnchor.constraint(equalTo: privacyPolicyWebView.bottomAnchor)
        ])
    }

}
