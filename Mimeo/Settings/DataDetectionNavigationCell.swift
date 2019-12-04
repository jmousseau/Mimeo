//
//  DataDetectionNavigationCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/23/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class DataDetectionNavigationCell: SettingCell {

    private var dataDetectionController: AnyFetchedResultController?

    public init(
        presenter: UIViewController,
        preferencesStore: PreferencesStore
    ) {
        super.init(
            title: "Data Detection",
            style: .value1,
            action: {
                let dataDetectionViewController = DataDetectionSettingViewController()
                dataDetectionViewController.view.tintColor = .mimeoYellow
                dataDetectionViewController.navigationItem.title = "Data Detection"
                dataDetectionViewController.navigationItem.largeTitleDisplayMode = .never
                presenter.navigationController?.pushViewController(
                    dataDetectionViewController,
                    animated: true
                )
            }
        )

        accessoryType = .disclosureIndicator
        detailTextLabel?.text = detailTextLabelText(
            for: preferencesStore.get(DataDetectionSetting.self)
        )

        dataDetectionController = preferencesStore.fetchedResultController(
            for: DataDetectionSetting.self,
            didChange: {
                self.detailTextLabel?.text = self.detailTextLabelText(
                    for: preferencesStore.get(DataDetectionSetting.self)
                )
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func detailTextLabelText(for dataDetection: DataDetectionSetting) -> String {
        dataDetection.isOn ? "On" : "Off"
    }

}

