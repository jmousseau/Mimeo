//
//  MimeoProViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class MimeoProViewController: StaticTableViewController {

    private let preferencesStore = PreferencesStore.default()

    public init() {
        super.init(style: .grouped)

        MimeoProSubscription.status(reload)
    }

    private func reload(for status: MimeoProSubscription.Status) {
        switch status {
        case .subscribed:
            sections = [makeSubscribedSection()]

        case .notSubscribed, .cancelled, .failed:
            sections = [makeNotSubscribedSection()]
        }

        sections.append(contentsOf: [
            Section(
                header: "Pro Settings",
                footer: """
                Payment will be charged to your Apple ID account at the confirmation of your purcahse. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.

                You can manage and cancel your subscriptions by going to your account settings in the App Store after purchase.
                """,
                cells: [
                    AppIconCell(
                        presenter: self,
                        preferencesStore: preferencesStore
                    ),
                    RecognitionHistoryCell(preferencesStore: preferencesStore)
                ]
            )
        ])

        tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeSubscribedSection() -> Section {
        Section(
            cells: [
                CancelSubscriptionCell(),
                RestorePurchasesCell(delegate: self)
            ]
        )
    }

    private func makeNotSubscribedSection() -> Section {
        Section(
            cells: [
                SubscribeCell(delegate: self),
                RestorePurchasesCell(delegate: self)
            ]
        )
    }

    private func makeFailedAlert(
        titlePrefix: String,
        error: Error?
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: "\(titlePrefix) Failed",
            message: error?.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default
        ))

        return alert
    }

}

extension MimeoProViewController: SubscribeCellDelegate {

    public func subscribeCellDidUpdate(status: MimeoProSubscription.Status) {
        switch status {
        case .subscribed, .notSubscribed, .cancelled:
            break

        case .failed(let error):
            present(
                makeFailedAlert(titlePrefix: "Subscription", error: error),
                animated: true
            )
        }

        reload(for: status)
    }

    public override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if cell is MimeoProSettingCell {
            MimeoProSubscription.status { status in
                switch status {
                case .subscribed:
                    cell.isUserInteractionEnabled = true
                    cell.contentView.alpha = 1

                case .notSubscribed, .cancelled, .failed:
                    cell.isUserInteractionEnabled = false
                    cell.contentView.alpha = 0.4
                }
            }
        }

        return cell
    }

}

extension MimeoProViewController: RestorePurchasesCellDelegate {

    public func restorePurchasesCellDidUpdate(
        status: MimeoProSubscription.Status
    ) {
        switch status {
        case .subscribed:
            present(makeRestorationAlert(), animated: true)

        case .notSubscribed, .cancelled:
            break

        case .failed(let error):
            present(
                makeFailedAlert(titlePrefix: "Restoration", error: error),
                animated: true
            )
        }

        reload(for: status)
    }

    private func makeRestorationAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: "Restoration Complete",
            message: "All your previous purchases have been restored.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default
        ))

        return alert
    }

}
