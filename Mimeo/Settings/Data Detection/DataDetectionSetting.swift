//
//  DataDetectionSetting.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/23/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation
import UIKit

/// The Data Detection setting.
public struct DataDetectionSetting: BooleanPreferenceStorable, Codable {

    /// The Data Detection preference key.
    public static var preferenceKey: String = "data-detection"

    /// The default Data Detection preference.
    public static var defaultPreference = DataDetectionSetting()

    /// The current data detection setting in an enabled state.
    public static var enabledCase: DataDetectionSetting {
        var dataDetectionSetting = PreferencesStore.default().get(DataDetectionSetting.self)
        dataDetectionSetting.isOn = true
        return dataDetectionSetting
    }

    /// The current data detection setting in a disabled state.
    public static var disabledCase: DataDetectionSetting {
        var dataDetectionSetting = PreferencesStore.default().get(DataDetectionSetting.self)
        dataDetectionSetting.isOn = false
        return dataDetectionSetting
    }

    /// The supported data detector types.
    public static var supportedDataDetectorTypes: [UIDataDetectorTypes] {
        [
            [.phoneNumber],
            [.link],
            [.address],
            [.calendarEvent],
            [.shipmentTrackingNumber],
            [.flightNumber]
        ]
    }

    /// Returns a data detection key path for a given data detector type.
    /// - Parameter dataDetectorType: The data detector type for which to return
    ///   a data detection setting key path.
    public static func keyPath(
        for dataDetectorType: UIDataDetectorTypes
    ) -> WritableKeyPath<DataDetectionSetting, Bool> {
        switch dataDetectorType {
        case [.phoneNumber]:
            return \.isPhoneNumberEnabled

        case [.link]:
            return \.isLinkEnabled

        case [.address]:
            return \.isAddressEnabled

        case [.calendarEvent]:
            return \.isCalendarEventEnabled

        case [.shipmentTrackingNumber]:
            return \.isShipmentTrackingNumberEnabled

        case [.flightNumber]:
            return \.isFlightNumberEnabled

        default:
            fatalError("Unhandled data detection type: \(dataDetectorType)")
        }
    }

    /// Is the Data Detection setting on?
    public var isOn: Bool = true

    /// Is phone number detection enabled?
    public var isPhoneNumberEnabled: Bool = true

    /// Is link detection enabled?
    public var isLinkEnabled: Bool = true

    /// Is address detection enabled?
    public var isAddressEnabled: Bool = true

    /// Is calendar event detection enabled?
    public var isCalendarEventEnabled: Bool = true

    /// Is shipment tracking number detection enabled?
    public var isShipmentTrackingNumberEnabled: Bool = true

    /// Is flight number detection enabed?
    public var isFlightNumberEnabled: Bool = true

    /// The Data Detector setting's enabled data detector types.
    public var enabledDataDetectorTypes: UIDataDetectorTypes {
        guard isOn else {
            return []
        }

        var dataDetectorTypes: UIDataDetectorTypes = []

        if isPhoneNumberEnabled {
            dataDetectorTypes.insert(.phoneNumber)
        }

        if isLinkEnabled {
            dataDetectorTypes.insert(.link)
        }

        if isAddressEnabled {
            dataDetectorTypes.insert(.address)
        }

        if isCalendarEventEnabled {
            dataDetectorTypes.insert(.calendarEvent)
        }

        if isShipmentTrackingNumberEnabled {
            dataDetectorTypes.insert(.shipmentTrackingNumber)
        }

        if isFlightNumberEnabled {
            dataDetectorTypes.insert(.flightNumber)
        }

        return dataDetectorTypes
    }

    /// The Data Detection setting's coding keys.
    public enum CodingKeys: String, CodingKey {

        /// The on coding key.
        case isOn = "is_on"

        /// The phone number enabled coding key.
        case isPhoneNumberEnabled = "is_phone_number_enabled"

        /// The link enabled coding key.
        case isLinkEnabled = "is_link_enabled"

        /// The address enabled coding key.
        case isAddressEnabled = "is_address_enabled"

        /// The calendar event enabled coding key.
        case isCalendarEventEnabled = "is_calendar_event_enabled"

        /// The shipment tracking number enabled coding key.
        case isShipmentTrackingNumberEnabled = "is_shipment_tracking_number_enabled"

        /// The flight number enabled coding key.
        case isFlightNumberEnabled = "is_flight_number_enabled"

    }

}
