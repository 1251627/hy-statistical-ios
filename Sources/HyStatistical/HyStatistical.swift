import Foundation
import UIKit

/// HyStatistical 数据埋点 iOS SDK
///
/// ```swift
/// HyStatistical.initialize(config: .init(apiKey: "ak_xxx"), appVersion: "1.4.2")
/// HyStatistical.track("subscribe_success", ["plan_id": "pro_monthly"])
/// HyStatistical.setUserId("user_123")
/// ```
public final class HyStatistical {
    public static let shared = HyStatistical()

    private var config: HyStatisticalConfig?
    private var queue: HyEventQueue?
    private var deviceId: String = ""
    private var userId: String?
    private var sessionId: String = ""
    private var appVersion: String = ""
    private var isInitialized = false

    private static let deviceIdKey = "com.hy.statistical.device_id"

    private init() {}

    public static func initialize(config: HyStatisticalConfig, appVersion: String = "") {
        shared.setup(config: config, appVersion: appVersion)
    }

    public static func track(_ eventName: String, _ properties: [String: Any]? = nil) {
        shared.trackInternal(eventName, properties: properties)
    }

    public static func setUserId(_ userId: String?) {
        shared.userId = userId
    }

    public static func setAppVersion(_ version: String) {
        shared.appVersion = version
    }

    public static func flush() {
        shared.queue?.flush()
    }

    public static var deviceId: String { shared.deviceId }
    public static var pendingCount: Int { shared.queue?.pendingCount ?? 0 }

    private func setup(config: HyStatisticalConfig, appVersion: String) {
        guard !isInitialized else { return }
        self.config = config
        self.appVersion = appVersion

        if let stored = HyKeychainHelper.read(key: Self.deviceIdKey) {
            deviceId = stored
        } else {
            deviceId = UUID().uuidString.lowercased()
            HyKeychainHelper.write(key: Self.deviceIdKey, value: deviceId)
        }

        sessionId = String(UUID().uuidString.prefix(8)).lowercased()

        queue = HyEventQueue(
            serverUrl: config.serverUrl,
            apiKey: config.apiKey,
            flushSize: config.flushSize,
            flushInterval: config.flushInterval,
            maxRetries: config.maxRetries
        )

        setupLifecycleObservers()
        isInitialized = true
        trackInternal("app_open")
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        sessionId = String(UUID().uuidString.prefix(8)).lowercased()
        trackInternal("app_foreground")
    }

    @objc private func appWillResignActive() {
        queue?.flush()
    }

    private func trackInternal(_ eventName: String, properties: [String: Any]? = nil) {
        guard isInitialized else { return }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var event: [String: Any] = [
            "platform": "ios",
            "event_name": eventName,
            "event_time": formatter.string(from: Date()),
            "device_id": deviceId,
            "session_id": "s_\(sessionId)",
            "insert_id": UUID().uuidString.lowercased(),
            "app_version": appVersion,
            "os_version": UIDevice.current.systemVersion,
        ]
        if let userId, !userId.isEmpty { event["user_id"] = userId }
        if let properties, !properties.isEmpty { event["properties"] = properties }
        queue?.add(event)
    }
}
