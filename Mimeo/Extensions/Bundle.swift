//
//  Bundle.swift
//  Mimeo
//
//  Created by Jack Mousseau on 11/8/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

extension Bundle {

    /// The application's display name.
    public var applicationDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    }

    /// The application's version.
    public var applicationVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as! String
    }

    /// The application's build number.
    public var applicationBuildNumber: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "0"
    }

}
