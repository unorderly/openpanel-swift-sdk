import Foundation

#if os(iOS)
    import UIKit

#elseif os(macOS)
    import AppKit
#endif
// MARK: - DeviceInfo

internal class DeviceInfo {
    static var isSimulatorOrTestFlight: Bool {
        isSimulator || isTestFlight
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    static var isDebug: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }

    static var isTestFlight: Bool {
        guard !isDebug, let path = Bundle.main.appStoreReceiptURL?.path else {
            return false
        }
        return path.contains("sandboxReceipt")
    }

    static var isAppStore: Bool {
        #if DEBUG
            return false
        #elseif TARGET_OS_OSX || TARGET_OS_MACCATALYST
            return false
        #elseif targetEnvironment(simulator)
            return false
        #else
            return !isSimulatorOrTestFlight
        #endif
    }

    /// The operating system and its version
    static var systemVersion: String {
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        let minorVersion = ProcessInfo.processInfo.operatingSystemVersion.minorVersion
        let patchVersion = ProcessInfo.processInfo.operatingSystemVersion.patchVersion
        return "\(platform) \(majorVersion).\(minorVersion).\(patchVersion)"
    }

    /// The major system version, i.e. iOS 15
    static var majorSystemVersion: String {
        return "\(platform) \(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)"
    }

    /// The major system version, i.e. iOS 15
    static var majorMinorSystemVersion: String {
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        let minorVersion = ProcessInfo.processInfo.operatingSystemVersion.minorVersion
        return "\(platform) \(majorVersion).\(minorVersion)"
    }

    /// The Bundle Short Version String, as described in Info.plist
    static var appVersion: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return appVersion ?? "0"
    }

    /// The Bundle Version String, as described in Info.plist
    static var buildNumber: String {
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return buildNumber ?? "0"
    }

    /// The extension identifer for the active resource, if available.
    ///
    /// This provides a value such as `com.apple.widgetkit-extension` when TelemetryDeck is run from a widget.
    static var extensionIdentifier: String? {
        let container = Bundle.main.infoDictionary?["NSExtension"] as? [String: Any]
        return container?["NSExtensionPointIdentifier"] as? String
    }

    static var deviceType: String {
#if os(macOS)
        return "Mac"
#elseif os(visionOS)
        return "Apple Vision"
#elseif os(iOS)
#if targetEnvironment(macCatalyst)
        return "Mac"
#else
        if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            return "Mac"
        } else {
            switch UIDevice.current.userInterfaceIdiom {
            case .mac: return "Mac"
            case .pad: return "iPad"
            case .tv: return "Apple TV"
            case .carPlay: return "CarPlay"
            case .vision: return "Apple Vision"
            default: return "Unknown"
            }
        }
#endif
#elseif os(watchOS)
        return "Apple Watch"
#elseif os(tvOS)
        return "Apple TV"
#else
        return "Unknown"
#endif
    }
    /// The modelname as reported by systemInfo.machine
    static var modelName: String {
        #if os(iOS)
            if #available(iOS 14.0, *) {
                if ProcessInfo.processInfo.isiOSAppOnMac {
                    var size = 0
                    sysctlbyname("hw.model", nil, &size, nil, 0)
                    var machine = [CChar](repeating: 0, count: size)
                    sysctlbyname("hw.model", &machine, &size, nil, 0)
                    return String(cString: machine)
                }
            }
        #endif

        #if os(macOS)
            if #available(macOS 11, *) {
                let service = IOServiceGetMatchingService(
                    kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
                var modelIdentifier: String?

                if let modelData = IORegistryEntryCreateCFProperty(
                    service, "model" as CFString, kCFAllocatorDefault, 0
                ).takeRetainedValue() as? Data {
                    if let modelIdentifierCString = String(data: modelData, encoding: .utf8)?
                        .cString(using: .utf8)
                    {
                        modelIdentifier = String(cString: modelIdentifierCString)
                    }
                }

                IOObjectRelease(service)
                if let modelIdentifier = modelIdentifier {
                    return modelIdentifier
                }
            }
        #endif

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// The build architecture
    static var architecture: String {
        #if arch(x86_64)
            return "x86_64"
        #elseif arch(arm)
            return "arm"
        #elseif arch(arm64)
            return "arm64"
        #elseif arch(i386)
            return "i386"
        #elseif arch(powerpc64)
            return "powerpc64"
        #elseif arch(powerpc64le)
            return "powerpc64le"
        #elseif arch(s390x)
            return "s390x"
        #else
            return "unknown"
        #endif
    }

    /// The operating system as reported by Swift. Note that this will report catalyst apps and iOS apps running on
    /// macOS as "iOS". See `platform` for an alternative.
    static var operatingSystem: String {
        #if os(macOS)
            return "macOS"
        #elseif os(visionOS)
            return "visionOS"
        #elseif os(iOS)
            return "iOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(tvOS)
            return "tvOS"
        #else
            return "Unknown Operating System"
        #endif
    }

    /// Based on the operating version reported by swift, but adding some smartness to better detect the actual
    /// platform. Should correctly identify catalyst apps and iOS apps on macOS.
    static var platform: String {
        #if os(macOS)
            return "macOS"
        #elseif os(visionOS)
            return "visionOS"
        #elseif os(iOS)
            #if targetEnvironment(macCatalyst)
                return "macCatalyst"
            #else
                if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
                    return "isiOSAppOnMac"
                }
                return "iOS"
            #endif
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(tvOS)
            return "tvOS"
        #else
            return "Unknown Platform"
        #endif
    }

    static var brand: String {
        "Apple"
    }

    /// The target environment as reported by swift. Either "simulator", "macCatalyst" or "native"
    static var targetEnvironment: String {
        #if targetEnvironment(simulator)
            return "simulator"
        #elseif targetEnvironment(macCatalyst)
            return "macCatalyst"
        #else
            return "native"
        #endif
    }

    /// The locale identifier the app currently runs in. E.g. `en_DE` for an app that does not support German on a device with preferences `[German, English]`, and region Germany.
    static var locale: String {
        return Locale.current.identifier
    }

    /// The region identifier both the user most prefers and also the app is set to. They are always the same because formatters in apps always auto-adjust to the users preferences.
    static var region: String {
        if #available(iOS 16, macOS 13, tvOS 16, visionOS 1, watchOS 9, *) {
            return Locale.current.region?.identifier ?? Locale.current.identifier.components(
                separatedBy: .init(charactersIn: "-_")
            ).last!
        } else {
            return Locale.current.regionCode ?? Locale.current.identifier.components(
                separatedBy: .init(charactersIn: "-_")
            ).last!
        }
    }

    /// The language identifier the app is currently running in. This represents the language the system (or the user) has chosen for the app to run in.
    static var appLanguage: String {
        if #available(iOS 16, macOS 13, tvOS 16, visionOS 1, watchOS 9, *) {
            return Locale.current.language.languageCode?.identifier
                ?? Locale.current.identifier.components(separatedBy: .init(charactersIn: "-_"))[0]
        } else {
            return Locale.current.languageCode
                ?? Locale.current.identifier.components(separatedBy: .init(charactersIn: "-_"))[0]
        }
    }

    /// The language identifier of the users most preferred language set on the device. Returns also languages the current app is not even localized to.
    static var preferredLanguage: String {
        let preferredLocaleIdentifier = Locale.preferredLanguages.first ?? "zz-ZZ"
        return preferredLocaleIdentifier.components(separatedBy: .init(charactersIn: "-_"))[0]
    }

    // Updated getUserAgent to generate a more standard-like UA string
    // Aiming for better compatibility with ua-parser-js used server-side
    // See: https://github.com/Openpanel-dev/openpanel/raw/refs/heads/main/packages/common/server/parser-user-agent.ts
    static func getUserAgent() -> String {
        // Use CFBundleName if available, otherwise fallback to bundleIdentifier
        let appName =
            Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main.bundleIdentifier
            ?? "UnknownApp"
        let appVersion = DeviceInfo.appVersion
        let buildNumber = DeviceInfo.buildNumber
        let sdkVersion = OpenPanel.sdkVersion
        let model = DeviceInfo.modelName  // e.g., iPhone14,5 or MacBookPro18,1
        let platform = DeviceInfo.platform  // e.g., iOS, macOS, macCatalyst
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        // Use underscores for OS version components, common in UAs (e.g., iPhone OS 15_4_1, Mac OS X 12_3_1)
        let osVersionStringUnderscore =
            "\(osVersion.majorVersion)_\(osVersion.minorVersion)_\(osVersion.patchVersion)"

        var ua = ""

        #if os(iOS)
            // Determine device type (iPhone/iPad) for the UA string
            let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
            // Define the OS name string based on platform/device type and version
            // Use "iPadOS" for iPads on iOS 13+ and Catalyst, otherwise "iPhone OS"
            let osNameString =
                (platform == "macCatalyst"
                    || (deviceType == "iPad" && osVersion.majorVersion >= 13))
                ? "iPadOS" : "iPhone OS"

            // Construct UA string mimicking standard iOS format
            // Example: Mozilla/5.0 (iPad; CPU iPadOS 15_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) AppName/1.0 (123) OpenPanel/0.0.1 Model/iPad13,1
            ua =
                "Mozilla/5.0 (\(deviceType); CPU \(osNameString) \(osVersionStringUnderscore) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) \(appName)/\(appVersion) (\(buildNumber)) OpenPanel/\(sdkVersion) Model/\(model)"

        #elseif os(macOS)
            // Construct UA string mimicking standard macOS format
            // Example: Mozilla/5.0 (Macintosh; Intel Mac OS X 12_3_1) AppleWebKit/605.1.15 (KHTML, like Gecko) AppName/1.0 (123) OpenPanel/0.0.1 Model/MacBookPro18,1
            ua =
                "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersionStringUnderscore)) AppleWebKit/605.1.15 (KHTML, like Gecko) \(appName)/\(appVersion) (\(buildNumber)) OpenPanel/\(sdkVersion) Model/\(model)"
        #else
//            // Generic fallback for other platforms (watchOS, tvOS) - less standard, might not parse as well
            let osVersionString =
                "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
            ua =
                "\(appName)/\(appVersion) (\(buildNumber); \(model); \(platform) \(osVersionString)) OpenPanel/\(sdkVersion)"
        #endif

        return ua
    }

    /// The devices current time zone in the modern `UTC` format, such as `UTC+1`, or `UTC-3:30`.
    static var timeZone: String {
        let secondsFromGMT = TimeZone.current.secondsFromGMT()
        let hours = secondsFromGMT / 3600
        let minutes = abs(secondsFromGMT / 60 % 60)

        let sign = secondsFromGMT >= 0 ? "+" : "-"
        if minutes > 0 {
            return "UTC\(sign)\(hours):\(String(format: "%02d", minutes))"
        } else {
            return "UTC\(sign)\(hours)"
        }
    }
}

// MARK: - Payload Types

public enum TrackHandlerPayload: Codable {
    case track(TrackPayload)
    case increment(IncrementPayload)
    case decrement(DecrementPayload)
    case alias(AliasPayload)
    case identify(IdentifyPayload)

    private enum CodingKeys: String, CodingKey {
        case type, payload
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .track(let payload):
            try container.encode("track", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .increment(let payload):
            try container.encode("increment", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .decrement(let payload):
            try container.encode("decrement", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .alias(let payload):
            try container.encode("alias", forKey: .type)
            try container.encode(payload, forKey: .payload)
        case .identify(let payload):
            try container.encode("identify", forKey: .type)
            try container.encode(payload, forKey: .payload)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "track":
            self = .track(try container.decode(TrackPayload.self, forKey: .payload))
        case "increment":
            self = .increment(try container.decode(IncrementPayload.self, forKey: .payload))
        case "decrement":
            self = .decrement(try container.decode(DecrementPayload.self, forKey: .payload))
        case "alias":
            self = .alias(try container.decode(AliasPayload.self, forKey: .payload))
        case "identify":
            self = .identify(try container.decode(IdentifyPayload.self, forKey: .payload))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }
}

public struct TrackPayload: Codable {
    public let name: String
    public var properties: [String: AnyCodable]?
    public var profileId: String?

    public init(name: String, properties: [String: AnyCodable]? = nil, profileId: String? = nil) {
        self.name = name
        self.properties = properties
        self.profileId = profileId
    }
}

public typealias TrackProperties = [String: Any]

extension AnyCodable:
    ExpressibleByStringLiteral,
    ExpressibleByBooleanLiteral,
    ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral,
    ExpressibleByArrayLiteral,
    ExpressibleByDictionaryLiteral
{
    public init(stringLiteral value: String) {
        self = AnyCodable(value)
    }

    public init(booleanLiteral value: Bool) {
        self = AnyCodable(value)
    }

    public init(integerLiteral value: Int) {
        self = AnyCodable(value)
    }

    public init(floatLiteral value: Double) {
        self = AnyCodable(value)
    }

    public init(arrayLiteral elements: AnyCodable...) {
        self = AnyCodable(elements)
    }

    public init(dictionaryLiteral elements: (String, AnyCodable)...) {
        let dict = Dictionary(elements, uniquingKeysWith: { first, _ in first })
        self = AnyCodable(dict)
    }
}

public struct IdentifyPayload: Codable {
    public let profileId: String
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var avatar: String?
    public var properties: [String: AnyCodable]?

    public init(
        profileId: String, firstName: String? = nil, lastName: String? = nil, email: String? = nil,
        avatar: String? = nil, properties: [String: AnyCodable]? = nil
    ) {
        self.profileId = profileId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.avatar = avatar
        self.properties = properties
    }
}

public struct AliasPayload: Codable {
    public let profileId: String
    public let alias: String

    public init(profileId: String, alias: String) {
        self.profileId = profileId
        self.alias = alias
    }
}

public struct IncrementPayload: Codable {
    public let profileId: String
    public let property: String
    public var value: Int?

    public init(profileId: String, property: String, value: Int? = nil) {
        self.profileId = profileId
        self.property = property
        self.value = value
    }
}

public struct DecrementPayload: Codable {
    public let profileId: String
    public let property: String
    public var value: Int?

    public init(profileId: String, property: String, value: Int? = nil) {
        self.profileId = profileId
        self.property = property
        self.value = value
    }
}

// MARK: - AnyCodable

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Date.self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map { $0.value }
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let value as AnyCodable:
            try container.encode(value)
        case let value as String:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as Date:
            try container.encode(value)
        case let value as [AnyCodable]:
            try container.encode(value)
        case let value as [String: AnyCodable]:
            try container.encode(value)
        case let value as [Any]:
            try container.encode(value.map { AnyCodable($0) })
        case let value as [String: Any]:
            try container.encode(value.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

// MARK: - OpenPanel Class

public class OpenPanel {
    public static let shared = OpenPanel()

    private let api: Api
    private var profileId: String?
    private let globalQueue = DispatchQueue(
        label: "com.openpanel.globalQueue", attributes: .concurrent)
    private var _global: [String: Any]?
    private var global: [String: Any]? {
        get { globalQueue.sync { _global } }
        set { globalQueue.async(flags: .barrier) { self._global = newValue } }
    }
    private var queue: [TrackHandlerPayload] = []
    private let operationQueue: OperationQueue

    public struct Options {
        public let clientId: String
        public var clientSecret: String?
        public var apiUrl: String?
        public var waitForProfile: Bool?
        public var filter: ((TrackHandlerPayload) -> Bool)?
        public var disabled: Bool?
        public var automaticTracking: Bool?

        public init(
            clientId: String, clientSecret: String? = nil, apiUrl: String? = nil,
            waitForProfile: Bool? = nil, filter: ((TrackHandlerPayload) -> Bool)? = nil,
            disabled: Bool? = nil, automaticTracking: Bool? = nil
        ) {
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.apiUrl = apiUrl
            self.waitForProfile = waitForProfile
            self.filter = filter
            self.disabled = disabled
            self.automaticTracking = automaticTracking
        }
    }

    private var options: Options?

    public static var sdkVersion: String {
        return "0.0.1"
    }

    public static var basicPayload: [String: Any] {
        [
            "__os": DeviceInfo.platform,
            "__osVersion": DeviceInfo.systemVersion,
            "__device": DeviceInfo.deviceType,
            "__model": DeviceInfo.modelName,
            "__brand": DeviceInfo.brand,

            "__version": DeviceInfo.appVersion,
            "__build": DeviceInfo.buildNumber,
            "__language": DeviceInfo.appLanguage,
            "__system_language": DeviceInfo.preferredLanguage,
            "__locale": DeviceInfo.locale,
            "__timezone": DeviceInfo.timeZone,
        ]
    }
    private init() {
        self.api = Api(config: Api.Config(baseUrl: "https://api.openpanel.dev"))
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 1
    }

    public static func initialize(options: Options) {
        shared.options = options

        var defaultHeaders: [String: String] = [
            "openpanel-client-id": options.clientId,
            "openpanel-sdk-name": "swift",
            "openpanel-sdk-version": OpenPanel.sdkVersion,
            "user-agent": DeviceInfo.getUserAgent(),
        ]

        if let clientSecret = options.clientSecret {
            defaultHeaders["openpanel-client-secret"] = clientSecret
        }

        shared.api.updateConfig(
            Api.Config(
                baseUrl: options.apiUrl ?? "https://api.openpanel.dev",
                defaultHeaders: defaultHeaders
            ))

        if options.automaticTracking == true {
            shared.setupAutomaticTracking()
        }
    }

    public static func ready() {
        shared.options?.waitForProfile = false
        shared.flush()
    }

    private func send(_ payload: TrackHandlerPayload) {
        guard let options = self.options else {
            logError("OpenPanel not initialized. Call OpenPanel.initialize() first.")
            return
        }

        if options.disabled == true {
            return
        }

        if let filter = options.filter, !filter(payload) {
            return
        }

        if options.waitForProfile == true, profileId == nil {
            queue.append(payload)
            return
        }

        let operation = BlockOperation {
            Task {
                let updatedPayload = self.ensureProfileId(payload)
                let result = await self.api.fetch(path: "/track", data: updatedPayload)
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.logError("Error sending payload: \(error)")
                }
            }
        }
        operationQueue.addOperation(operation)
    }

    private func ensureProfileId(_ payload: TrackHandlerPayload) -> TrackHandlerPayload {
        switch payload {
        case .track(var trackPayload):
            if trackPayload.profileId == nil {
                trackPayload.profileId = self.profileId
            }
            return .track(trackPayload)
        default:
            return payload
        }
    }

    public static func setGlobalProperties(_ properties: [String: Any]) {
        shared.globalQueue.async(flags: .barrier) {
            if var global = shared._global {
                for (key, value) in properties {
                    global[key] = value
                }
                shared._global = global
            } else {
                shared._global = properties
            }
        }
    }

    public static func track(name: String, properties: TrackProperties? = nil) {
        let mergedProperties = shared.globalQueue.sync {
            var merged = self.basicPayload
            if let global = shared._global {
                merged.merge(global) { (_, new) in new }
            }

            if let properties = properties {
                merged.merge(properties) { (_, new) in new }
            }
            return merged
        }
        let payload = TrackPayload(
            name: name,
            properties: mergedProperties.mapValues { AnyCodable($0) },
            profileId: properties?["profileId"] as? String ?? shared.profileId
        )
        shared.send(.track(payload))
    }

    public static func identify(payload: IdentifyPayload) {
        shared.profileId = payload.profileId
        shared.flush()

        if payload.firstName != nil || payload.lastName != nil || payload.email != nil
            || payload.avatar != nil || !(payload.properties?.isEmpty ?? true)
        {
            var updatedPayload = payload
            shared.globalQueue.sync {
                if let global = shared._global {
                    var mergedProperties = global
                    if let payloadProperties = payload.properties {
                        mergedProperties.merge(payloadProperties) { (_, new) in
                            (new as AnyObject).value
                        }
                    }
                    updatedPayload.properties = mergedProperties.mapValues { AnyCodable($0) }
                }
            }
            shared.send(.identify(updatedPayload))
        }
    }

    public static func alias(payload: AliasPayload) {
        shared.send(.alias(payload))
    }

    public static func increment(payload: IncrementPayload) {
        shared.send(.increment(payload))
    }

    public static func decrement(payload: DecrementPayload) {
        shared.send(.decrement(payload))
    }

    public static func clear() {
        shared.profileId = nil
        shared.globalQueue.async(flags: .barrier) {
            shared._global = nil
        }
    }

    public func flush() {
        let currentQueue = queue
        queue.removeAll()
        for item in currentQueue {
            send(item)
        }
    }

    public static func flush() {
        shared.flush()
    }

    private func setupAutomaticTracking() {
        #if os(iOS) || os(tvOS)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneDidActivate),
                name: UIScene.didActivateNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneDidEnterBackground),
                name: UIScene.didEnterBackgroundNotification,
                object: nil
            )
        #elseif os(macOS)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidBecomeActive),
                name: NSApplication.didBecomeActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillTerminate),
                name: NSApplication.willTerminateNotification,
                object: nil
            )
        #endif
    }

    #if os(iOS) || os(tvOS)
        @objc private func sceneDidActivate(_ notification: Notification) {
            guard let scene = notification.object as? UIScene,
                scene.activationState == .foregroundActive,
                UIApplication.shared.connectedScenes.filter({
                    $0.activationState == .foregroundActive
                }).count == 1
            else {
                return
            }
            OpenPanel.track(name: "app_opened")
        }

        @objc private func sceneDidEnterBackground(_ notification: Notification) {
            guard
                UIApplication.shared.connectedScenes.filter({ $0.activationState != .background })
                    .isEmpty
            else {
                return
            }
            OpenPanel.track(name: "app_closed")
        }
    #elseif os(macOS)
        @objc private func appDidBecomeActive() {
            OpenPanel.track(name: "app_opened")
        }

        @objc private func appWillTerminate() {
            OpenPanel.track(name: "app_closed")
        }
    #endif

    private func logError(_ message: String) {
        print("OpenPanel Error: \(message)")
    }
}

// MARK: - Api Class

internal class Api {
    private var baseUrl: String
    private var headers: [String: String]
    private var maxRetries: Int
    private var initialRetryDelay: TimeInterval

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    struct Config {
        let baseUrl: String
        var defaultHeaders: [String: String]?
        var maxRetries: Int?
        var initialRetryDelay: TimeInterval?
    }

    init(config: Config) {
        self.baseUrl = config.baseUrl
        self.headers = config.defaultHeaders ?? [:]
        self.headers["Content-Type"] = "application/json"
        self.maxRetries = config.maxRetries ?? 3
        self.initialRetryDelay = config.initialRetryDelay ?? 0.5
    }

    func updateConfig(_ config: Config) {
        self.baseUrl = config.baseUrl
        self.headers = config.defaultHeaders ?? [:]
        self.headers["Content-Type"] = "application/json"
        self.maxRetries = config.maxRetries ?? 3
        self.initialRetryDelay = config.initialRetryDelay ?? 0.5
    }

    func addHeader(key: String, value: String) {
        headers[key] = value
    }

    private func post<T: Codable>(url: URL, data: T, options: [String: Any] = [:], attempt: Int = 0)
        async -> Result<Data, Error>
    {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        do {
            request.httpBody = try Self.encoder.encode(data)
        } catch {
            return .failure(error)
        }

        for (key, value) in options {
            if let stringValue = value as? String {
                request.setValue(stringValue, forHTTPHeaderField: key)
            }
        }

        print("OpenPanel:", "Sending", String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "", headers)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("OpenPanel:", "Invalid response")
                return .failure(
                    NSError(
                        domain: "HTTPError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("OpenPanel:", "HTTP error: \(httpResponse.statusCode)")
                return .failure(
                    NSError(
                        domain: "HTTPError", code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"
                        ]))
            }

            print("OpenPanel:", "Success", String(data: data, encoding: .utf8) ?? "")

            return .success(data)
        } catch {
            if attempt < maxRetries {
                let delay = initialRetryDelay * pow(2.0, Double(attempt))
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return await post(url: url, data: data, options: options, attempt: attempt + 1)
            }
            return .failure(error)
        }
    }

    func fetch<T: Codable>(path: String, data: T, options: [String: Any] = [:]) async -> Result<
        Data, Error
    > {
        guard let url = URL(string: baseUrl + path) else {
            return .failure(
                NSError(
                    domain: "URLError", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        return await post(url: url, data: data, options: options)
    }
}
