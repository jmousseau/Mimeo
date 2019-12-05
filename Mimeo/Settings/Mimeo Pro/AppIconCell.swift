//
//  AppIconCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/4/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class AppIconCell: SettingCell, MimeoProSettingCell {

    private var fetchedResultController: AnyFetchedResultController?

    init(
        presenter: UIViewController,
        preferencesStore: PreferencesStore
    ) {
        super.init(
            title: "App Icon",
            style: .value1,
            shouldDeselectCellOnSelection: true
        ) {
            let actionSheet = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .actionSheet
            )

            for appIcon in AppIcon.allCases {
                actionSheet.addAction(UIAlertAction(
                    title: appIcon.name,
                    style: .default,
                    handler: { _ in
                        preferencesStore.set(appIcon)
                        actionSheet.dismiss(animated: true)
                    }
                ))
            }

            actionSheet.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: { _ in
                    actionSheet.dismiss(animated: true)
                }
            ))

            actionSheet.view.tintColor = .mimeoYellow

            presenter.present(actionSheet, animated: true)
        }

        fetchedResultController = preferencesStore.fetchedResultController(
            for: AppIcon.self,
            didChange: {
                let appIcon = preferencesStore.get(AppIcon.self)
                UIApplication.shared.set(appIcon: appIcon)
                self.detailTextLabel?.text = appIcon.name
            }
        )

        detailTextLabel?.text = preferencesStore.get(AppIcon.self).name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
