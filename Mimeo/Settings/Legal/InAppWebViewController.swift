//
//  InAppWebViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 1/14/20.
//  Copyright © 2020 Jack Mousseau. All rights reserved.
//

import UIKit
import WebKit

/// A generic in-app web view controller.
public class InAppWebViewController: UIViewController {

    /// The privacy policy view controller's privacy policy web view.
    private let webView = WKWebView(frame: .zero)

    /// Initialize a privacy policy view controller.
    public init(url urlString: String) {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .systemBackground

        let privacyPolicyURL = URL(string: urlString)!
        webView.load(URLRequest(url: privacyPolicyURL))
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Web View Navigation

extension InAppWebViewController: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        guard webView.superview == nil else {
            return
        }

        addWebview()
    }

}

// MARK: - View Layout

extension InAppWebViewController {

    private func addWebview() {
        view.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            view.topAnchor.constraint(equalTo: webView.topAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        ])
    }

}
