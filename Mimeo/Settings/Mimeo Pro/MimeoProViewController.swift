//
//  MimeoProViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import Purchases

public final class MimeoProViewController: StaticTableViewController {

    public init() {
        super.init(style: .grouped)

        MimeoProSubscription.status(reload)
    }

    private func reload(for status: MimeoProSubscription.Status) {
        switch status {
        case .subscribed:
            sections = [makeSubscribedSection()]

        case .notSubscribed:
            sections = [makeNotSubscribedSection()]

        case .cancelled, .failed:
            break
        }

        tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeSubscribedSection() -> Section {
        Section(
            cells: [
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
        case .subscribed:
            present(makeSubscribedAlert(), animated: true)

        case .notSubscribed, .cancelled:
            break

        case .failed(let error):
            present(
                makeFailedAlert(titlePrefix: "Subscription", error: error),
                animated: true
            )
        }

        reload(for: status)
    }

    private func makeSubscribedAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: "Subscribed",
            message: "Thank you for subscribing to Mimeo Pro.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: "OK",
            style: .default
        ))

        return alert
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
