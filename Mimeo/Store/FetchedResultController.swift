//
//  FetchedResultController.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/10/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData

/// A type-erased fetched result controller.
public class AnyFetchedResultController: NSObject { }

/// A fetched result controller.
///
/// Similiar to a fetched *results* controller, but only for a single object.
public final class FetchedResultController<
    ManagedObject: NSManagedObject
>: AnyFetchedResultController, NSFetchedResultsControllerDelegate {

    /// The fetched result controller's internal controller.
    private let controller: NSFetchedResultsController<ManagedObject>

    /// The fetched result controller's change closure.
    private let didChange: () -> Void

    /// Initialize a fetched result controller.
    /// - Parameters:
    ///   - fetchRequest: The fetched result controller's fetch request.
    ///   - managedObjectContext: The managed object context for which to
    ///     initialize the fetched result controller.
    ///   - didChange: The fetched result controller's change closure.
    public init(
        fetchRequest: NSFetchRequest<ManagedObject>,
        managedObjectContext: NSManagedObjectContext,
        didChange: @escaping () -> Void
    ) {
        fetchRequest.fetchLimit = 1

        controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        self.didChange = didChange

        super.init()

        controller.delegate = self
        try? controller.performFetch()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(type(of: self).didRecieveRemoteTransactions(_:)),
            name: .didRecieveRemoteTransactions,
            object: nil
        )
    }

    public func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        // External changes are handled by `didRecieveRemoteTransactions`.
        guard controller.managedObjectContext.hasChanges else {
            return
        }

        didChange()
    }

    @objc private func didRecieveRemoteTransactions(
        _ notification: NSNotification
    ) {
        guard let transactions = notification.userInfo?[
            Store.transactionsUserInfoKey
        ] as? [NSPersistentHistoryTransaction] else {
            preconditionFailure()
        }

        let changes = transactions.reduce([]) { changes, transaction in
            changes + (transaction.changes ?? [])
        }

        let changedObjectIds = changes.reduce([]) { changedObjectIds, change in
            changedObjectIds + [change.changedObjectID]
        }

        let fetchRequest = controller.fetchRequest.copy() as! NSFetchRequest<NSFetchRequestResult>
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            controller.fetchRequest.predicate,
            NSPredicate(format: "self IN %@", changedObjectIds)
        ].compactMap({ $0 }))

        guard let changedObjectCount = try? controller.managedObjectContext.count(
            for: fetchRequest
        ) else {
            return
        }

        if changedObjectCount > 0 {
            DispatchQueue.main.async {
                self.didChange()
            }
        }
    }

}
