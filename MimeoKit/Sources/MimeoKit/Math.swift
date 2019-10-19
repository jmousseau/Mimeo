//
//  Statistics.swift
//  MimeoKit
//
//  Created by Jack Mousseau on 10/7/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

extension Sequence where Element: AdditiveArithmetic {

    /// The sum of the sequence's elements.
    func sum() -> Element {
        reduce(.zero, +)
    }

}

extension Collection where Element == Double {

    /// The mean of the collection's elements.
    func mean() -> Double {
        sum() / Double(count)
    }

}
