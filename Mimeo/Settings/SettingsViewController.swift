//
//  SettingsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/19/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit
import MessageUI

public final class SettingsViewController: StaticTableViewController {

    private let preferenceStore = PreferencesStore.default()

    public override var sections: [StaticTableViewController.Section] {
        [
            Section(
                cells: [
                    RecognitionLanguageNavigationCell(presenter: self)
                ]
            ),
            Section(
                footer: "Faster text recognition, but lower accuracy.",
                cells: [
                    BooleanSettingCell(
                        title: "Quick Recognition",
                        preferenceStore: preferenceStore,
                        preference: QuickRecognitionSetting.self
                    )
                ]
            ),
            Section(
                header: "Feedback",
                cells: [
                    RateAppCell(),
                    SendFeedbackCell(presenter: self)
                ]
            )
        ]
    }

    public init() {
        super.init(style: .grouped)

        tableView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        deselectRowForSelectedIndexPath()
    }

}

// MARK: - Table View Delegate

extension SettingsViewController {

    public override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if let cell = tableView.cellForRow(at: indexPath) as? NavigationSettingCell {
            cell.action()

            if cell.shouldDeselectCellOnSelection {
                deselectRowForSelectedIndexPath()
            }
        }
    }

}
