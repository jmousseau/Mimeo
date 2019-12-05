//
//  SettingsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/19/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import MessageUI
import Purchases
import UIKit

public final class SettingsViewController: StaticTableViewController {

    private let preferencesStore = PreferencesStore.default()

    public init() {
        super.init(style: .grouped)

        navigationItem.title = "Settings"
        navigationItem.rightBarButtonItem = .makeDoneButton(
            target: self,
            action: #selector(dismissAnimated)
        )

        tableView.delegate = self

        sections = [
            Section(
                cells: [
                    RecognitionLanguageNavigationCell(presenter: self)
                ]
            ),
            Section(
                footer: "Automatically detect phone numbers, links, etc.",
                cells: [
                    DataDetectionNavigationCell(
                        presenter: self,
                        preferencesStore: preferencesStore
                    )
                ]
            ),
            Section(
                footer: "Faster text recognition, but lower accuracy.",
                cells: [
                    BooleanSettingCell(
                        title: "Quick Recognition",
                        preferenceStore: preferencesStore,
                        preference: QuickRecognitionSetting.self
                    )
                ]
            ),
            Purchases.canMakePayments() ? Section(
                cells: [
                    MimeoProNavigationCell(presenter: self)
                ]
            ) : nil,
            Section(
                cells: [
                    RateAppCell(preferencesStore: preferencesStore),
                    SendFeedbackCell(presenter: self)
                ]
            ),
            Section(
                cells: [
                    PrivacyPolicyNavigationCell(presenter: self),
                    AboutNavigationCell(presenter: self)
                ]
            )
        ].compactMap({ $0 })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func dismissAnimated() {
        dismiss(animated: true)
    }

}

// MARK: - Recognition Language Delegate {

extension SettingsViewController: RecognitionLanguageViewControllerDelegate {

    public func recognitionLanguageViewController(
        _ recognitionLanguageViewController: RecognitionLanguageViewController,
        didSelectLanguage language: RecognitionLanguage
    ) {
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }

}


// MARK: - Mail Composer Delegate

extension SettingsViewController : MFMailComposeViewControllerDelegate {

    public func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
        tableView.deselectRowForSelectedIndexPath()
    }

}
