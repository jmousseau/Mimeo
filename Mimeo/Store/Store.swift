//
//  Store.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/21/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData
import Foundation
import UIKit

/// Store notifications.
extension Notification.Name {

    /// The store recieved remove transactions.
    static let didRecieveRemoteTransactions = Notification.Name("didRecieveRemoteTransactions")

}

/// The local store.
///
/// Synced to iCloud.
public final class Store {

    /// The store's view context.
    public static let viewContext: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.store.persistentContainer.viewContext
    }()

    /// The Store's transactions user info key
    public static let transactionsUserInfoKey = "transactions"

    /// The store's persistent container name.
    private let containerName: String

    /// The store's author.
    private let author = "mimeo-ios-app"

    /// The store's persistent container.
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: containerName)

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Container is missing store description")
        }

        description.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )

        description.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = author
        container.viewContext.automaticallyMergesChangesFromParent = true

        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Unabled to set query generation: \(error)")
        }

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unable to load persisten stores: \(error)")
            }
        })

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(type(of: self).remoteStoreDidChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: nil
        )

        return container
    }()

    /// The store's persistent history token store.
    private lazy var persistentHistoryTokenStore: PersistentHistoryTokenStore = {
        return PersistentHistoryTokenStore(containerName: containerName)
    }()

    /// The store's persistent history queue.
    ///
    /// Used to process external changes.
    private lazy var persistentHistoryQueue: OperationQueue = {
        let persistentHistoryQueue = OperationQueue()
        persistentHistoryQueue.maxConcurrentOperationCount = 1
        return persistentHistoryQueue
    }()

    /// Initialize a store.
    /// - Parameter containerName: The store's persistent container name.
    public init(containerName: String) {
        self.containerName = containerName
    }

}

// MARK: - Notifications

extension Store {

    /// The remote store did change.
    /// - Parameter notification: The remote store change notification.
    @objc private func remoteStoreDidChange(_ notification: NSNotification) {
        persistentHistoryQueue.addOperation {
            self.processPersistentHistory()
        }
    }

}

// MARK: - Processing History

extension Store {

    /// Process the persistent history.
    private func processPersistentHistory() {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.performAndWait {
            guard let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest else {
                return
            }

            historyFetchRequest.predicate = NSPredicate(format: "author != %@", author)

            let historyChangeFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(
                after: self.persistentHistoryTokenStore.lastKnownToken
            )

            historyChangeFetchRequest.fetchRequest = historyFetchRequest

            let historyChangeResult = try? backgroundContext.execute(
                historyChangeFetchRequest
            ) as? NSPersistentHistoryResult

            guard let transactions = historyChangeResult?.result as? [NSPersistentHistoryTransaction] else{
                return
            }

            guard !transactions.isEmpty else {
                return
            }

            NotificationCenter.default.post(
                name: .didRecieveRemoteTransactions,
                object: self,
                userInfo: [
                    Self.transactionsUserInfoKey: transactions
                ]
            )

            defer {
                persistentHistoryTokenStore.lastKnownToken = transactions.last?.token
            }

            let transactionChanges = transactions.compactMap({ transaction in
                transaction.changes
            }).reduce([], +)

            let objectIdentifiers = transactionChanges.compactMap({ change in
                change.changeType == .insert ? change.changedObjectID : nil
            })

            guard !objectIdentifiers.isEmpty else {
                return
            }

            deduplicate(
                objectIdentifiers: objectIdentifiers,
                ofType: Preference.self,
                in: backgroundContext,
                by: \.key
            )
        }
    }

}

// MARK: - Key Path Deduplication

extension Store {

    /// Deduplicate object identifiers of a certain managed object type by
    /// comparing key path values.
    /// - Parameters:
    ///   - objectIdentifiers: The object identifiers to deduplicate.
    ///   - type: The type of managed object to deduplicate.
    ///   - context: The context in which to perform the deduplication.
    ///   - keyPath: The key path used for object deduplication.
    private func deduplicate<T: NSManagedObject, U: Comparable>(
        objectIdentifiers: [NSManagedObjectID],
        ofType type: T.Type,
        in context: NSManagedObjectContext,
        by keyPath: KeyPath<T, U?>
    ) {
        let objectIdentifiersForType = objectIdentifiers.filter({ objectIdentifier in
            objectIdentifier.entity.name == T.entity().name
        })

        context.performAndWait {
            objectIdentifiersForType.forEach({ objectIdentifer in
                self.deduplicate(
                    objectIdentifier: objectIdentifer,
                    ofType: type,
                    in: context,
                    by: keyPath
                )
            })

            guard context.hasChanges else {
                return
            }

            do {
                try context.save()
            } catch {
                fatalError("Unable to save context: \(error)")
            }
        }

    }

    /// Deduplicate an object identifier of a certain managed object type by
    /// comparing key path values.
    /// - Parameters:
    ///   - objectIdentifier: The object identifier to deduplicate.
    ///   - type: The type of managed object to deduplicate.
    ///   - context: The context in which to perform the deduplication.
    ///   - keyPath: The key path used for object deduplication.
    private func deduplicate<T: NSManagedObject, U: Comparable>(
        objectIdentifier: NSManagedObjectID,
        ofType type: T.Type,
        in context: NSManagedObjectContext,
        by keyPath: KeyPath<T, U?>
    ) {
        guard let object = context.object(with: objectIdentifier) as? T else {
            return
        }

        let fetchRequest = T.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "self != %@", objectIdentifier)

        guard let existingObjects = try? context.fetch(fetchRequest) as? [T] else {
            return
        }

        guard !existingObjects.isEmpty else {
            return
        }

        let objectValue = object[keyPath: keyPath]

        for existingObject in existingObjects {
            guard objectValue == existingObject[keyPath: keyPath] else {
                continue
            }

            context.delete(object)
        }
    }

}
