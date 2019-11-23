//
//  DataDetectionSettingViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/23/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class DataDetectionSettingViewController: StaticTableViewController {

    private let preferencesStore = PreferencesStore.default()

    private var dataDetectionController: AnyFetchedResultController?

    private let supportedDataDetectorTypes = DataDetectionSetting.supportedDataDetectorTypes

    public init() {
        super.init(style: .grouped)

        navigationItem.largeTitleDisplayMode = .never

        tableView.dataSource = self
        tableView.delegate = self

        sections = [
            Section(
                cells: [
                    BooleanSettingCell(
                        title: "Data Detection",
                        preferenceStore: preferencesStore,
                        preference: DataDetectionSetting.self
                    )
                ]
            )
        ]

        if preferencesStore.get(DataDetectionSetting.self).isOn {
            addDataDetectionCells()
        }

        dataDetectionController = preferencesStore.fetchedResultController(
            for: DataDetectionSetting.self,
            didChange: {
                let isOn = self.preferencesStore.get(DataDetectionSetting.self).isOn
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()

                    let dataDetectionSection = IndexSet(integer: 1)

                    // Add the data detection cells.
                    if isOn && self.tableView.numberOfSections == 1 {
                        self.addDataDetectionCells()
                        self.tableView.insertSections(dataDetectionSection, with: .top)
                    }

                    // Remove the data detection cells.
                    if !isOn && self.tableView.numberOfSections == 2 {
                        self.removeDataDetectionCells()
                        self.tableView.deleteSections(dataDetectionSection, with: .top)
                    }

                    // Reload the data detection cells to update checkmarks.
                    if isOn && self.tableView.numberOfSections == 2 {
                        self.tableView.reloadSections(dataDetectionSection, with: .none)
                    }

                    self.tableView.endUpdates()
                }
            }
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addDataDetectionCells() {
        sections.append(Section(
            header: "Data Types",
            cells: supportedDataDetectorTypes.map(DataDetectionTypeCell.init)
        ))
    }

    private func removeDataDetectionCells() {
        sections.removeLast()
    }

}

extension DataDetectionSettingViewController {

    public override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        if cell is DataDetectionTypeCell {
            let dataDetectionSetting = preferencesStore.get(DataDetectionSetting.self)
            let dataDetectorType = supportedDataDetectorTypes[indexPath.row]
            let dataDetecorTypeKeyPath = DataDetectionSetting.keyPath(for: dataDetectorType)

            cell.accessoryType = dataDetectionSetting[keyPath: dataDetecorTypeKeyPath] ? .checkmark : .none
        }

        return cell
    }

    public override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if let cell = tableView.cellForRow(at: indexPath) as? DataDetectionTypeCell {
            let dataDetectorType = supportedDataDetectorTypes[indexPath.row]
            let dataDetecorTypeKeyPath = DataDetectionSetting.keyPath(for: dataDetectorType)

            var dataDetectionSetting = preferencesStore.get(DataDetectionSetting.self)
            dataDetectionSetting[keyPath: dataDetecorTypeKeyPath].toggle()
            preferencesStore.set(dataDetectionSetting)

            cell.accessoryType = dataDetectionSetting[keyPath: dataDetecorTypeKeyPath] ? .checkmark : .none
            cell.setSelected(false, animated: true)
        }
    }

}
