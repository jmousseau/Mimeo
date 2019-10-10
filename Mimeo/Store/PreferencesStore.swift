//
//  PreferencesStore.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData
import UIKit

public protocol PreferenceStorable: RawRepresentable where RawValue == String {

    static var preferenceKey: RawValue { get }

    static var defaultPreferenceValue: RawValue { get }

}

extension PreferenceStorable {

    public var preferenceValue: RawValue {
        rawValue
    }

}

public struct PreferencesStore: KeyValueStore {

    public static func `default`() -> PreferencesStore {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return PreferencesStore(
            managedObjectContext: appDelegate.persistentContainer.viewContext
        )
    }

    private let managedObjectContext: NSManagedObjectContext

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    public func get<P: PreferenceStorable>(_ preference: P.Type) -> P {
        P(rawValue: try! getValue(for: P.preferenceKey) ?? P.defaultPreferenceValue)!
    }

    public func set<P: PreferenceStorable>(_ preference: P) {
        try! set(
            value: preference.preferenceValue,
            for: P.preferenceKey
        )
    }

    public func getValue(for key: String) throws -> String? {
        try fetchPreference(for: key).value
    }

    public func set(value: String?, for key: String) throws {
        let preference = try fetchPreference(for: key)
        preference.value = value
        try preference.managedObjectContext?.save()
    }

    public func fetchPreference(for key: String) throws -> Preference {
        let fetchRequest: NSFetchRequest<Preference> = Preference.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)

        if let preference = try managedObjectContext.fetch(fetchRequest).first {
            return preference
        } else {
            let preference = Preference(context: managedObjectContext)
            preference.key = key
            return preference
        }
    }

}
