//
//  PersistentHistoryTokenStore.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/22/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData
import Foundation

/// A store which saves the last known persistent history token.
public struct PersistentHistoryTokenStore {

    /// The Core Data container name for which to store the persistent history
    /// token.
    private let containerName: String

    /// The file at which the persistent history token is stored.
    private var tokenFile: URL {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(
            "Mimeo",
            isDirectory: true
        )

        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                fatalError("Unable to create history token file")
            }
        }

        return url.appendingPathComponent(
            "history-token.data",
            isDirectory: false
        )
    }

    /// The last known peristent history token.
    ///
    /// Setting the token will save it to the store.
    public var lastKnownToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastKnownToken else {
                return
            }

            guard let tokenData = try? NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            ) else {
                return
            }

            do {
                try tokenData.write(to: tokenFile)
            } catch {
                fatalError("Unable to save history token: \(error)")
            }
        }
    }

    /// Initialize a persistent history token store.
    /// - Parameter containerName: The persistent history token store's
    ///   container name.
    public init(containerName: String) {
        self.containerName = containerName

        guard let tokenData = try? Data(contentsOf: tokenFile) else {
            return
        }

        lastKnownToken = try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSPersistentHistoryToken.self,
            from: tokenData
        )
    }

}
