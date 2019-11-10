//
//  RateAppCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/8/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import StoreKit

/// The app review request app store URL.
private let AppReviewRequestAppStoreURL = "itms-apps://itunes.apple.com/app/id"

/// The Mimeo copy app identifier.
private let MimeoCopyAppIdentifier = "1483871459"

/// The maximum number of app review request alerts.
private let AppReviewRequestMaximumAlertCount = 3

/// The period of time in which the maximum number of review request alerts may
/// be made.
///
/// Should be exactly 365 days but added a bit of extra time just to be safe.
private let AppReviewRequestPeriod: TimeInterval = 86400 * (365 + 2)

/// A request to review the app.
public struct AppReviewRequest: PreferenceStorable, Codable {

    /// The app review request's preference key.
    public static var preferenceKey: String = "app-review-request"

    /// The app review request's default preference.
    public static var defaultPreference = AppReviewRequest()

    /// The dates on which the alerts were shown.
    public private(set) var requestDates = [Date]()

    /// Request an app review.
    public mutating func requestReview() {
        let now = Date()
        requestDates = requestDates.filter({ requestDate in
            now.timeIntervalSince(requestDate) < AppReviewRequestPeriod
        })

        if requestDates.count < AppReviewRequestMaximumAlertCount {
            SKStoreReviewController.requestReview()

            if requestDates.count == AppReviewRequestMaximumAlertCount {
                requestDates = requestDates.sorted()
                requestDates.removeFirst()
            }

            requestDates.append(Date())
        } else {
            let url = URL(string: "\(AppReviewRequestAppStoreURL)\(MimeoCopyAppIdentifier)")!

            guard UIApplication.shared.canOpenURL(url) else {
                return
            }

            UIApplication.shared.open(url, options: [:])
        }
    }

    /// The app review request's coding keys.
    public enum CodingKeys: String, CodingKey {

        /// The dates coding key.
        case requestDates = "request_dates"

    }

}

public final class RateAppCell: NavigationSettingCell {

    public init(preferencesStore: PreferencesStore) {
        super.init(
            title: "Rate \(Bundle.main.applicationDisplayName)",
            shouldDeselectCellOnSelection: true
        ) {
            var appReviewRequest = preferencesStore.get(AppReviewRequest.self)
            appReviewRequest.requestReview()
            preferencesStore.set(appReviewRequest)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
