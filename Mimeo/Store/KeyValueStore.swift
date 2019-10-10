//
//  KeyValueStore.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import Foundation

public protocol KeyValueStore {

    associatedtype Key: Equatable
    associatedtype Value

    func getValue(for: Key) throws -> Value

    func set(value: Value, for: Key) throws

}
