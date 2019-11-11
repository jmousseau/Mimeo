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
    }

    public func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        didChange()
    }

}
