//
//  TableViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public class StaticTableViewController: UITableViewController {

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

    public var sections = [Section]()

    public override init(style: UITableView.Style) {
        super.init(style: style)

        tableView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func deselectRowForSelectedIndexPath() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
}

// MARK: - Table View Data Source

extension StaticTableViewController {

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


