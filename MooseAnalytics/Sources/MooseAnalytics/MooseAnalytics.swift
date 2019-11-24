import Foundation

/// An application installlation store.
public protocol ApplicationInstallationStore {

    /// The store's installation identifier.
    var installationIdentifer: String { get set }

}

/// The base moose analytics object.
@available(iOS 10.0, *)
public struct MooseAnalytics {

    // MARK: - Credentials

    /// Moose analytics credentials.
    public struct Credentials {

        /// The application identifier.
        public let applicationIdentifier: String

        /// The application secret.
        public let applicationSecret: String

        /// Initialize a credentials object.
        /// - Parameters:
        ///   - applicationIdentifier: The credential's application identifier.
        ///   - applicationSecret: The credential's application secret.
        public init(
            applicationIdentifier: String,
            applicationSecret: String
        ) {
            self.applicationIdentifier = applicationIdentifier
            self.applicationSecret = applicationSecret
        }

    }

    // MARK: - Event Request

    /// An event request.
    fileprivate struct EventRequest<Payload: Encodable>: Encodable {

        /// The event's version.
        fileprivate let version: UInt

        /// The event's application installation identifier.
        fileprivate let applicationInstallationIdentifier: String

        /// The event's application version.
        fileprivate let applicationVersion: String

        /// The event's application build number.
        fileprivate let applicationBuildNumber: UInt

        /// The event's collection.
        fileprivate let collection: String

        /// The event's payload.
        fileprivate let payload: Payload

        /// The data at which the event occurred.
        fileprivate let occurredAt: Date

        /// Initialize an event request.
        /// - Parameters:
        ///   - version: The event's version.
        ///   - applicationInstallationIdentifier: The event's application
        ///     installation identifier.
        ///   - applicationVersion: The event's application version.
        ///   - applicationBuildNumber: The event's application build number.
        ///   - collection: The event's application collection.
        ///   - payload: The event's payload.
        ///   - occurredAt: The data at which the event occured.
        fileprivate init(
            version: UInt,
            applicationInstallationIdentifier: String,
            applicationVersion: String,
            applicationBuildNumber: UInt,
            collection: String,
            payload: Payload,
            occurredAt: Date = Date()
        ) {
            self.version = version
            self.applicationInstallationIdentifier = applicationInstallationIdentifier
            self.applicationVersion = applicationVersion
            self.applicationBuildNumber = applicationBuildNumber
            self.collection = collection
            self.payload = payload
            self.occurredAt = occurredAt
        }

        /// The event's coding keys.
        fileprivate enum CodingKeys: String, CodingKey {

            /// The event's version coding key.
            case version = "version"

            /// The event's application installation id coding key.
            case applicationInstallationIdentifier = "application_installation_id"

            /// The event's application version coding key.
            case applicationVersion = "application_version"

            /// The event's application build number coding key.
            case applicationBuildNumber = "application_build_number"

            /// The event's collection coding key.
            case collection = "collection"

            /// The event's payload coding key.
            case payload = "payload"

            /// The event's occurred at coding key.
            case occurredAt = "occurred_at"

        }

    }

    /// The analytics API credentials used for authentication.
    private let credentials: Credentials

    /// The analytics API's endpoint.
    private let endpoint: URL

    /// The application installation store in which to store the application
    /// installation identifier.
    private let applicationInstallationStore: ApplicationInstallationStore

    /// The application bundle for which to record events.
    private let bundle: Bundle

    /// The application bundle's application version.
    private var bundleApplicationVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as! String
    }

    /// The application bundle's application build number.
    private var bundleApplicationBuildNumber: UInt {
        guard let versionString = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String else {
            return 0
        }

        return UInt(versionString) ?? 0
    }

    /// Initialize a moose analytics object.
    /// - Parameters:
    ///   - applicationIdentifer: The anlytics API credentials used for
    ///     authentication.
    ///   - endpoint: The analytics API's endpoint.
    ///   - applicationInstallationStore: The application installation store in
    ///     which to store the application installation identifier.
    ///   - bundle: The application bundle for which to record events.
    public init(
        credentials: Credentials,
        endpoint: URL,
        applicationInstallationStore: ApplicationInstallationStore,
        bundle: Bundle
    ) {
        self.credentials = credentials
        self.endpoint = endpoint
        self.applicationInstallationStore = applicationInstallationStore
        self.bundle = bundle
    }

    // MARK: - Recording Events

    /// Record an analytics event.
    /// - Parameter event: The event to record.
    public func record<Event: AnalyticsEvent>(event: Event) throws {
        let eventRequest = EventRequest(
            version: event.version,
            applicationInstallationIdentifier: applicationInstallationStore
                .installationIdentifer,
            applicationVersion: bundleApplicationVersion,
            applicationBuildNumber: bundleApplicationBuildNumber,
            collection: event.collection,
            payload: event.payload
        )

        try send(event: eventRequest)
    }

    /// Send an event to the analytics API.
    ///
    /// Sending an event is best effort. Events are not queued locally or resent
    /// upon failure.
    ///
    /// - Parameter event: The event which to send to the analytics API.
    private func send<Payload: Encodable>(event: EventRequest<Payload>) throws {
        let jsonEncoder = makeJSONEncoder()
        let data = try jsonEncoder.encode(event)

        var request = URLRequest(url: url(for: .events))
        request.httpMethod = "POST"
        request.httpBody = data

        addCredentials(to: &request)

        URLSession.shared.dataTask(with: request).resume()
    }

    /// Make a JSON encoder that is compatible with the moose analytics API.
    private func makeJSONEncoder() -> JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        return jsonEncoder
    }

    /// Add API credentials to a request.
    /// - Parameter request: The request to which to add the credentials.
    private func addCredentials(to request: inout URLRequest) {
        request.addValue(
            credentials.applicationIdentifier,
            forHTTPHeaderField: "X-Application-Identifier"
        )

        request.addValue(
            credentials.applicationSecret,
            forHTTPHeaderField: "X-Application-Secret"
        )
    }

}

// MARK: - Version 1 Routes

@available(iOS 10.0, *)
extension MooseAnalytics {

    /// The version 1 routes avaiable in the moose analytics API
    fileprivate enum Version1Route: String {

        /// The event's route.
        case events = "events"

    }

    /// Returns the URL for an API version 1 route.
    /// - Parameter route: The route for which to construct a URL.
    fileprivate func url(for route: Version1Route) -> URL {
        var url = endpoint
        url.appendPathComponent("v1")
        url.appendPathComponent(route.rawValue)
        return url
    }

}
