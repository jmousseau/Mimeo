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

}
