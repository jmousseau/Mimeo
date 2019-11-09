//
//  SettingsViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/19/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit
import MessageUI

public final class SettingsViewController: UITableViewController {

    private let preferenceStore = PreferencesStore.default()

    public struct Section {

        public let header: String?

        public let footer: String?

        public var cells: [UITableViewCell]

        public init(
            header: String? = nil,
            footer: String? = nil,
            cells: [UITableViewCell]
        ) {
            self.header = header
            self.footer = footer
            self.cells = cells
        }

    }

    private var sections = [Section]()

    public init() {
        super.init(style: .grouped)

        setUpSections()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpSections() {
        sections = [
            Section(
                footer: "Faster text recognition, but lower accuracy.",
                cells: [
                    BooleanSettingCell(
                        title: "Quick Recognition",
                        isOn: preferenceStore.get(QuickRecognitionSetting.self) == .on,
                        onToggle: { isOn in
                            self.preferenceStore.set(isOn ? QuickRecognitionSetting.on : .off)
                        }
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

    fileprivate func deselectRowForSelectedIndexPath() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
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

// MARK: - Table View Data Source

extension SettingsViewController {

    public override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    public override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        sections[section].cells.count
    }

    public override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        sections[section].header
    }

    public override func tableView(
        _ tableView: UITableView,
        titleForFooterInSection section: Int
    ) -> String? {
        sections[section].footer
    }

    public override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        sections[indexPath.section].cells[indexPath.row]
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
