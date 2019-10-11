//
//  KeyValueStore.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

/// A key value store.
public protocol KeyValueStore {

    /// The store's key type.
    associatedtype Key: Equatable

    /// The store's value type.
    associatedtype Value

    /// Returns a value for the specified key.
    /// - Parameter key: The key for which to return the corresponding value.
    func getValue(for key: Key) throws -> Value?

    /// Set a value for the specified key.
    /// - Parameter value: The value to store.
    /// - Parameter ke: The key under which to store the `value`.
    func set(value: Value?, for: Key) throws

}
