//
//  RecognitionLanguageViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public protocol RecognitionLanguageViewControllerDelegate: class {

    func recognitionLanguageViewController(
        _ recognitionLanguageViewController: RecognitionLanguageViewController,
        didSelectLanguage language: RecognitionLanguage
    )

}

public final class RecognitionLanguageViewController: UITableViewController {

    private let preferencesStore = PreferencesStore.default()

    private let supportedLanguages = RecognitionLanguage.supportedLanguages

    public weak var delegate: RecognitionLanguageViewControllerDelegate?

    public init() {
        super.init(style: .grouped)

        navigationItem.largeTitleDisplayMode = .never

        tableView.register(
            RecognitionLanguageCell.self,
            forCellReuseIdentifier: RecognitionLanguageCell.identifier
        )

        tableView.tableFooterView = UIView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: Table View Data Source

extension RecognitionLanguageViewController {

    public override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        supportedLanguages.count
    }

    public override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: RecognitionLanguageCell.identifier,
            for: indexPath
        )

        cell.textLabel?.text = supportedLanguages[indexPath.row].descriptionWithRegion

        if supportedLanguages[indexPath.row] == preferencesStore.get(RecognitionLanguage.self) {
            cell.accessoryType = .checkmark
        }

        return cell
    }

}

// MARK: - Table View Delegate

extension RecognitionLanguageViewController {

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 0,
            RecognitionLanguage.supportedLanguages.count == 1,
            let language = RecognitionLanguage.supportedLanguages.first else {
            return nil
        }

        return "Currently, \(language.descriptionWithRegion) is the only supported language."
    }

    public override func tableView(
        _ tableView: UITableView,
        willSelectRowAt indexPath: IndexPath
    ) -> IndexPath? {
        let selectedIndexPath = tableView.indexPathForSelectedRow ?? IndexPath(
            row: supportedLanguages.firstIndex(of: preferencesStore.get(RecognitionLanguage.self)) ?? 0,
            section: 0
        )

        if let selectedCell = tableView.cellForRow(at: selectedIndexPath) as? RecognitionLanguageCell {
            selectedCell.accessoryType = .none
        }

        return indexPath
    }

    public override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        let language = supportedLanguages[indexPath.row]
        preferencesStore.set(language)
        delegate?.recognitionLanguageViewController(
            self,
            didSelectLanguage: language
        )

        if let cell = tableView.cellForRow(at: indexPath) as? RecognitionLanguageCell {
            cell.accessoryType = .checkmark
            cell.setSelected(false, animated: true)
        }
    }

}
