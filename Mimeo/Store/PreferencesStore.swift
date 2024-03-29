//
//  PreferencesStore.swift
//  Mimeo
//
//  Created by Jack Mousseau on 10/9/19.
//  Copyright © 2019 Jack Mousseau. All rights reserved.
//

import CoreData
import UIKit

// MARK: - Preference Storable

/// A type which may be stored in the preferences store.
public protocol PreferenceStorable: Equatable {

    /// The key under which the preference is stored.
    static var preferenceKey: String { get }

    /// The default preference.
    static var defaultPreference: Self { get }

    /// The preference's value.
    var preferenceValue: String { get }

    /// Initialize a preference storable with a given preference value.
    /// - Parameter preferenceValue: The preference value with which to
    /// initialize a preference storable.
    init?(preferenceValue: String)

}

// MARK: - Core Data

extension PreferenceStorable {

    fileprivate static func fetchRequest() -> NSFetchRequest<Preference> {
        Preference.fetchRequest(for: preferenceKey)
    }

}

// MARK: - Raw Representable

/// Default preference storable raw string representable implementation.
extension PreferenceStorable where Self: RawRepresentable, Self.RawValue == String {

    public var preferenceValue: String {
        rawValue
    }

    public init?(preferenceValue: String) {
        self.init(rawValue: preferenceValue)
    }

}

// MARK: - Codable

/// Default preference storable codable implementation.
extension PreferenceStorable where Self: Codable {

    public var preferenceValue: String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(self) else {
            return Self.defaultPreference.preferenceValue
        }

        return String(data: data, encoding: .utf8) ?? Self.defaultPreference.preferenceValue
    }

    public init?(preferenceValue: String) {
        guard let data = preferenceValue.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let decodedSelf = try? decoder.decode(
            Self.self,
            from: data
        ) else {
            return nil
        }

        self = decodedSelf
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
        return self == .enabledCase
    }

    /// Toggle the preference.
    mutating func toggle() {
        self = isEnabled ? .disabledCase : .enabledCase
    }

}

// MARK: - Preferences Store

/// A preference store backed by Core Data.
public struct PreferencesStore {

    /// Returns a new default preference store instance.
    public static func `default`() -> PreferencesStore {
        PreferencesStore(managedObjectContext: Store.viewContext)
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
        if let preferenceValue = try? getValue(for: P.preferenceKey), let preference = P(
            preferenceValue: preferenceValue
        ) {
            return preference
        } else {
            // Although tempting, do not set the default preference value, just
            // return it. Setting the default preference value will cause a core
            // data recursive save crash.
            return P.defaultPreference
        }
    }

    /// Set a preference.
    /// - Parameter preference: The preference to set.
    public func set<P: PreferenceStorable>(_ preference: P) {
        try! set(
            value: preference.preferenceValue,
            for: P.preferenceKey
        )
    }

    /// Create a fetched result controller for a given preference.
    /// - Parameters:
    ///   - preference: The preference for which to create a fetched result
    ///     controller.
    ///   - didChange: The fetched result controller's change closure.
    public func fetchedResultController<P: PreferenceStorable>(
        for preference: P.Type,
        didChange: @escaping () -> Void
    ) -> AnyFetchedResultController {
        Preference.fetchedResultController(
            for: preference.preferenceKey,
            managedObjectContext: managedObjectContext,
            didChange: didChange
        )
    }

}


extension PreferencesStore: KeyValueStore {

    public func getValue(for key: String) throws -> String? {
        try fetchPreference(for: key).value
    }

    public func set(value: String?, for key: String) throws {
        let preference = try fetchPreference(for: key)

        guard preference.value != value else {
            return
        }

        preference.value = value
        try preference.managedObjectContext?.save()
    }

    /// Fetch a preference object from the managed object context for the
    /// specified key, if it exists. Otherwise, create a new preference object
    /// and with a key of `key`.
    /// - Parameter key: The for which to fetch a preference object.
    private func fetchPreference(for key: String) throws -> Preference {
        let fetchRequest = Preference.fetchRequest(for: key)
        if let preference = try managedObjectContext.fetch(fetchRequest).first {
            return preference
        } else {
            let preference = Preference(context: managedObjectContext)
            preference.key = key
            return preference
        }
    }

}

// MARK: - Preference

extension Preference {

    /// Create a preference fetch request for a given key.
    /// - Parameter key: The key for which to create the fetch request.
    fileprivate static func fetchRequest(
        for key: String
    ) -> NSFetchRequest<Preference> {
        let fetchRequest: NSFetchRequest<Preference> = Preference.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        return fetchRequest
    }

    /// Create a preference fetched result controller for the given key.
    /// - Parameters:
    ///   - key: The key for which to create a preference fetched result
    ///     controller.
    ///   - managedObjectContext: The managed object context with which to
    ///     create the fetched result controller.
    ///   - didChange: A closure that is called when the fetched result
    ///     controller's content changes.
    fileprivate static func fetchedResultController(
        for key: String,
        managedObjectContext: NSManagedObjectContext,
        didChange: @escaping () -> Void
    ) -> FetchedResultController<Preference> {
        let fetchRequest = Preference.fetchRequest(for: key)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "key", ascending: true)]

        return FetchedResultController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            didChange: didChange
        )
    }

}
