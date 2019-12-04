//
//  AppDelegate.swift
//  Mimeo
//
//  Created by Jack Mousseau on 9/29/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CloudKit
import Purchases
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// The application's store.
    lazy var store: Store = {
        Store(containerName: "Mimeo")
    }()

    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        configurePurchases()

        UINavigationBar.appearance().tintColor = .mimeoYellow

        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting
        connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }

    private func configurePurchases() {
        if Purchases.canMakePayments() {
            #if DEBUG
            Purchases.debugLogsEnabled = true
            #endif

            CKContainer.default().fetchUserRecordID { userRecordID, _ in
                Purchases.configure(
                    withAPIKey: RevenueCatAPIKey,
                    appUserID: userRecordID?.recordName
                )
            }
        }

    }

}

