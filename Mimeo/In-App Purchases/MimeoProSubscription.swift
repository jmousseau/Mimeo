//
//  MimeoProSubscription.swift
//  Mimeo
//
//  Created by Jack Mousseau on 12/3/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import Purchases

public struct MimeoProSubscription {

    public static let settingsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    private static let productIdentifier = "mimeopro"

    public enum Status: Equatable {

        public static func == (lhs: MimeoProSubscription.Status, rhs: MimeoProSubscription.Status) -> Bool {
            switch (lhs, rhs) {
            case (.subscribed, .subscribed),
                 (.notSubscribed, .notSubscribed),
                 (.cancelled, .cancelled),
                 (.failed, .failed):
                return true

            default:
                return false
            }
        }

        case subscribed

        case notSubscribed

        case cancelled

        case failed(error: Error?)

    }

    public static func status(_ completion: @escaping (Status) -> Void) {
        Purchases.shared.purchaserInfo { purchaseInfo, error in
            completion(status(for: purchaseInfo, error: error))
        }
    }

    public static func isSubscribed(_ completion: @escaping () -> Void) {
        status { subscriptionStatus in
            if (subscriptionStatus == .subscribed) {
                completion()
            }
        }
    }

    public static func annualPackage(_ completion: @escaping (Purchases.Package) -> Void) {
        Purchases.shared.offerings { offerings, error in
            guard let offerings = offerings else {
                return
            }

            guard let mimeoProAnnualPackage = offerings[Self.productIdentifier]?.annual else {
                return
            }

            completion(mimeoProAnnualPackage)
        }
    }

    public static func subscribe(_ completion: @escaping (Status) -> Void) {
        // Just to be super safe, check payments permission.
        guard Purchases.canMakePayments() else {
            return
        }

        annualPackage { annualPackage in
            Purchases.shared.purchasePackage(annualPackage) { _, purchaseInfo, error, cancelled in
                guard !cancelled else {
                    completion(.cancelled)
                    return
                }

                completion(status(for: purchaseInfo, error: error))
            }
        }
    }

    public static func restore(_ completion: @escaping (Status) -> Void) {
        Purchases.shared.restoreTransactions { purchaseInfo, error in
            completion(status(for: purchaseInfo, error: error))
        }
    }

    private static func status(
        for purchaseInfo: Purchases.PurchaserInfo?,
        error: Error?
    ) -> Status {
        guard let activeSubscriptions = purchaseInfo?.activeSubscriptions else {
            return .failed(error: error)
        }

        let isSubscribed = activeSubscriptions.contains(Self.productIdentifier)
        return isSubscribed ? .subscribed : .notSubscribed
    }

}
