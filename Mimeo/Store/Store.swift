//
//  Store.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/21/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData
import Foundation

/// The local store.
///
/// Synced to iCloud.
public final class Store {

    /// The store's persistent container.
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Mimeo")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Container is missing store description")
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = "mimeo-ios-app"
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

        return container
    }()

}
