//
//  ApplicationInstallationStore.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/24/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import MooseAnalytics

/// The application installation store's user defaults key.
private let ApplicationInstallationStoreUserDefaultsKey = "application-installation-store"

extension UserDefaults: ApplicationInstallationStore {

    public var installationIdentifer: String {
        get {
            if string(forKey: ApplicationInstallationStoreUserDefaultsKey) == nil {
                set(
                    UUID().uuidString,
                    forKey: ApplicationInstallationStoreUserDefaultsKey
                )
            }

           return string(forKey: ApplicationInstallationStoreUserDefaultsKey)!
        }

        set(newInstallationIdentifer) {
            set(
                newInstallationIdentifer,
                forKey: ApplicationInstallationStoreUserDefaultsKey
            )
        }
    }

}
