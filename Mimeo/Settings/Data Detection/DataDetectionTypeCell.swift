//
//  DataDetectionTypeCell.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/23/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import UIKit

public final class DataDetectionTypeCell: UITableViewCell {

    public static let identifier = "data-detection-type-cell"

    public init(dataDetectorType: UIDataDetectorTypes) {
        super.init(style: .default, reuseIdentifier: Self.identifier)

        let (title, imageName) = cellItems(for: dataDetectorType)
        let configuration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView?.image = UIImage(
            systemName: imageName,
            withConfiguration: configuration
        )
        textLabel?.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func cellItems(for dataDetectorType: UIDataDetectorTypes) -> (
        title: String,
        imageName: String
    ) {
        switch dataDetectorType {
        case [.phoneNumber]:
            return ("Phone Numbers", "phone")

        case [.link]:
            return ("Links", "link")

        case [.address]:
            return ("Addresses", "house")

        case [.calendarEvent]:
            return ("Calendar Events", "calendar")

        case [.shipmentTrackingNumber]:
            return ("Shipment Tracking Numbers", "cube.box")

        case [.flightNumber]:
            return ("Flight Numbers", "airplane")

        default:
            fatalError("Unhandled data detection type: \(dataDetectorType)")
        }
    }

}
