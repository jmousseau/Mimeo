//
//  RecognitionHistoryViewController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/5/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData
import UIKit

public final class RecognitionHistoryViewController: UITableViewController {

    public final class Cell: UITableViewCell {

        fileprivate static let identifier = "recognition-history-cell"

        fileprivate lazy var textView: UITextView = {
            let textView = LinkResponsiveTextView()
            textView.backgroundColor = .clear
            textView.font = .systemFont(ofSize: 17)
            textView.tintColor = .mimeoYellow
            return textView
        }()

        public override init(
            style: UITableViewCell.CellStyle,
            reuseIdentifier: String?
        ) {
            super.init(style: .default, reuseIdentifier: reuseIdentifier)

            addTextView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        public override func prepareForReuse() {
            textView.text = nil
        }

        private func addTextView() {
            contentView.addSubview(textView)

            textView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
                textView.topAnchor.constraint(equalTo: contentView.topAnchor),
                textView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
                textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }

    }

    private let preferencesStore = PreferencesStore.default()

    private lazy var recognitionHistoryFetchedResultsControler: NSFetchedResultsController<
        RecognitionResult
    > = {
        let fetchRequest: NSFetchRequest<RecognitionResult> = RecognitionResult.fetchRequest()
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(
            key: "createdAt", ascending: false
        )]

        let recognitionHistoryFetchedResultsControler = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: Store.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        recognitionHistoryFetchedResultsControler.delegate = self

        return recognitionHistoryFetchedResultsControler
    }()

    private lazy var centerTableViewLabel: UILabel = {
        let centerTableViewLabel = UILabel()
        centerTableViewLabel.numberOfLines = 0
        centerTableViewLabel.textColor = .secondaryLabel
        centerTableViewLabel.textAlignment = .center
        return centerTableViewLabel
    }()

    public init() {
        super.init(style: .plain)

        navigationItem.title = "History"
        navigationItem.rightBarButtonItem = .makeDoneButton(
            target: self,
            action: #selector(dismissAnimated)
        )

        tableView.tableFooterView = UIView()
        tableView.register(
            Cell.classForCoder(),
            forCellReuseIdentifier: Cell.identifier
        )

        MimeoProSubscription.status { status in
            switch status {
            case .subscribed:
                try? self.recognitionHistoryFetchedResultsControler.performFetch()

            case .notSubscribed, .cancelled, .failed:
                self.updateCenterTableViewLabel(
                    text: "Keep track of your recognition history by subscribing to Mimeo Pro."
                )
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCenterTableViewLabel(text: String?) {
        if let text = text {
            centerTableViewLabel.text = text
            centerTableViewLabel.bounds = tableView.bounds
            tableView.backgroundView = centerTableViewLabel
        } else {
            centerTableViewLabel.text = nil
            tableView.backgroundView = nil
        }
    }

    @objc private func dismissAnimated() {
        dismiss(animated: true)
    }

}

// MARK: - Table View Data Source

extension RecognitionHistoryViewController {

    public override func numberOfSections(in tableView: UITableView) -> Int {
        recognitionHistoryFetchedResultsControler.sections?.count ?? 0
    }

    public override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        recognitionHistoryFetchedResultsControler.sections![section].numberOfObjects
    }

    public override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: Cell.identifier,
            for: indexPath
        ) as? Cell else {
            fatalError("Dequeue resuable cell failed with identifier: \(Cell.identifier)")
        }

        cell.textView.dataDetectorTypes = preferencesStore
            .get(DataDetectionSetting.self)
            .enabledDataDetectorTypes

        cell.textView.text = recognitionHistoryFetchedResultsControler
            .object(at: indexPath).text

        return cell
    }

}

// MARK: - Table View Delegate

extension RecognitionHistoryViewController {

    public override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        guard let text = recognitionHistoryFetchedResultsControler
            .object(at: indexPath).text else {
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            tableView.deselectRowForSelectedIndexPath()
        }

        present(activityViewController, animated: true)
    }

}

// MARK: - Fetched Results Delegate

extension RecognitionHistoryViewController: NSFetchedResultsControllerDelegate {

    public func controllerWillChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        tableView.beginUpdates()
    }

    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?, for
        type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }

        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }

        case .update:
            if let indexPath = indexPath {
                tableView.reloadRows(at: [indexPath], with: .none)
            }

        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }

        @unknown default:
            fatalError("Unhandled fetched results change type.")
        }
    }

    public func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        if let recognitionResultCount = controller.sections?.first?.numberOfObjects,
            recognitionResultCount == 0 {
            self.updateCenterTableViewLabel(
                text: "Your recognition history is empty."
            )
        } else {
            self.updateCenterTableViewLabel(text: nil)
        }

        tableView.endUpdates()
    }

}
