//
//  PreferencesStore.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData
import UIKit

/// A type which may be stored in the preferences store.
public protocol PreferenceStorable: RawRepresentable where RawValue == String {

    /// The key under which the preference is stored.
    static var preferenceKey: String { get }

    /// The default preference value.
    static var defaultPreferenceValue: Self { get }

}

extension PreferenceStorable {

    /// The preference storable's preference value.
    public var preferenceValue: RawValue {
        rawValue
    }

}

/// A protocol to mark a particular preference as boolean representable.
public protocol BooleanPreferenceStorable: PreferenceStorable {

    /// The preference's enabled case.
    static var enabledCase: Self { get }

    /// The preference's disabled case.
    static var disabledCase: Self { get }

}

extension BooleanPreferenceStorable {

    /// Is the preference enabled?
    var isEnabled: Bool {
        return self == Self.enabledCase
    }

}

/// A preference store backed by Core Data.
public struct PreferencesStore {

    /// Returns a new default preference store instance.
    public static func `default`() -> PreferencesStore {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return PreferencesStore(
            managedObjectContext: appDelegate.persistentContainer.viewContext
        )
    }

    /// The preference store's managed object context.
    private let managedObjectContext: NSManagedObjectContext

    /// Initialize a preference store.
    /// - Parameter managedObjectContext: The preference store's managed object
    ///   context.
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    /// Get a preference.
    /// - Parameter preference: The preference type.
    public func get<P: PreferenceStorable>(_ preference: P.Type) -> P {
        P(rawValue: (try? getValue(for: P.preferenceKey)) ?? P.defaultPreferenceValue.rawValue)!
    }

    /// Set a preference.
    /// - Parameter preference: The preference to set.
    public func set<P: PreferenceStorable>(_ preference: P) {
        try! set(
            value: preference.preferenceValue,
            for: P.preferenceKey
        )
    }

    /// Fetch a preference object from the managed object context for the
    /// specified key, if it exists. Otherwise, create a new preference object
    /// and with a key of `key`.
    /// - Parameter key: The for which to fetch a preference object.
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


extension PreferencesStore: KeyValueStore {

    public func getValue(for key: String) throws -> String? {
        try fetchPreference(for: key).value
    }

    public func set(value: String?, for key: String) throws {
        let preference = try fetchPreference(for: key)
        preference.value = value
        try preference.managedObjectContext?.save()
    }

}
