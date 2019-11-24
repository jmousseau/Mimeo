import Foundation

/// An analytics event.
public protocol AnalyticsEvent {

    /// The analytics event's payload type.
    associatedtype Payload: Encodable

    /// The analytics event's version.
    var version: UInt { get }

    /// The analytics event's collection.
    var collection: String { get }

    /// The analytics event's payload
    var payload: Payload { get }

}
