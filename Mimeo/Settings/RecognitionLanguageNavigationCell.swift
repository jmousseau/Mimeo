//
//  RecognitionLanguageNavigationCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class RecognitionLanguageNavigationCell: NavigationSettingCell {

    private let preferencesStore = PreferencesStore.default()

    public init(
        presenter: UIViewController & RecognitionLanguageViewControllerDelegate
    ) {
        super.init(
            title: "Recognition Language",
            style: .value1,
            action: {
                let recognitionLanguageViewController = RecognitionLanguageViewController()
                recognitionLanguageViewController.delegate = presenter
                recognitionLanguageViewController.view.tintColor = .mimeoYellow
                recognitionLanguageViewController.navigationItem.title = "Language"
                presenter.navigationController?.pushViewController(
                    recognitionLanguageViewController,
                    animated: true
                )
            }
        )

        detailTextLabel?.text = preferencesStore.get(RecognitionLanguage.self).description
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
