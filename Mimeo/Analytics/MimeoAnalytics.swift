//
//  MimeoAnalytics.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/24/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import MooseAnalytics

/// Mimeo analytics.
public struct MimeoAnalytics {

    /// A Mimo Analytics collection.
    private enum Collection: String {

        /// The recognized text event.
        case recognizedText = "recognized-text"

    }

    /// The Mimeo analytics events.
    public enum Events {

        /// A recognized text event.
        public struct RecognizedTextEvent: AnalyticsEvent {

            /// A recongized text event payload.
            public struct Payload: Encodable {

                /// The payload's total recognzied text length.
                public let totalRecognizedTextLength: UInt

                /// Initialize a recognized text event payload.
                /// - Parameter totalRecognizedTextLength: The payload's total
                ///   recognized text length.
                public init(totalRecognizedTextLength: UInt) {
                    self.totalRecognizedTextLength = totalRecognizedTextLength
                }

                /// The payload's coding keys.
                public enum CodingKeys: String, CodingKey {

                    /// The total recognized text length coding key.
                    case totalRecognizedTextLength = "total_recognized_text_length"

                }

            }

            /// The recognized text event's version.
            public var version: UInt = 1

            /// The recognized text event's collection.
            public var collection: String = Collection.recognizedText.rawValue

            /// The recongized text event's payload.
            public var payload: Payload

            /// Initialize a recongized text event.
            /// - Parameter totalRecognizedTextLength: The event's total
            ///   recognized text length.
            public init(totalRecognizedTextLength: UInt) {
                self.payload = Payload(
                    totalRecognizedTextLength: totalRecognizedTextLength
                )
            }

        }

    }

    /// The Mimeo analytics shared instance.
    public static let shared = MimeoAnalytics()

    /// The moose analytics API object.
    private let mooseAnalytics: MooseAnalytics = {
        MooseAnalytics(
            credentials: MimeoAnalyticsCredentials,
            endpoint: URL(string: "https://analytics.jmousseau.com")!,
            applicationInstallationStore: UserDefaults.standard,
            bundle: Bundle.main
        )
    }()

    /// Record an anlytics event.
    /// - Parameter event: The event to record.
    public func record<Event: AnalyticsEvent>(event: Event) {
        try? mooseAnalytics.record(event: event)
    }

}
