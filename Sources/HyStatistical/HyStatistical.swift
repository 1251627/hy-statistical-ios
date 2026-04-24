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
    private var enableLog = false

    private static let deviceIdKey = "com.hy.statistical.device_id"

    private init() {}

    public static func initialize(config: HyStatisticalConfig, appVersion: String = "", userId: String? = nil) {
        shared.setup(config: config, appVersion: appVersion, userId: userId)
    }

    public static func track(_ eventName: String, _ properties: [String: Any]? = nil) {
        shared.trackInternal(eventName, properties: properties)
    }

    public static func setUserId(_ userId: String?) {
        shared.userId = userId
        shared.log("setUserId \(userId ?? "(nil)")")
    }

    public static func setAppVersion(_ version: String) {
        shared.appVersion = version
    }

    public static func flush() {
        shared.queue?.flush()
    }

    /// 清空内存队列和离线缓存里所有待发事件。
    public static func clearPending() {
        shared.queue?.clearPending()
    }

    public static var deviceId: String { shared.deviceId }
    public static var pendingCount: Int { shared.queue?.pendingCount ?? 0 }

    private func setup(config: HyStatisticalConfig, appVersion: String, userId: String?) {
        guard !isInitialized else { return }
        self.config = config
        self.appVersion = appVersion
        self.enableLog = config.enableLog
        // 在 lifecycle 首条 app_open 触发之前设好 userId，保证它也带 user_id
        if let userId, !userId.isEmpty { self.userId = userId }

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
            maxRetries: config.maxRetries,
            enableLog: config.enableLog
        )

        setupLifecycleObservers()
        isInitialized = true

        if enableLog {
            let masked = config.apiKey.count > 8 ? "\(config.apiKey.prefix(8))***" : "***"
            print("[HyStatistical] init serverUrl=\(config.serverUrl) apiKey=\(masked) "
                  + "deviceId=\(deviceId) appVersion=\(appVersion) "
                  + "osVersion=\(UIDevice.current.systemVersion) "
                  + "flushInterval=\(config.flushInterval)s flushSize=\(config.flushSize) "
                  + "maxRetries=\(config.maxRetries) userId=\(userId ?? "(nil)")")
        }

        log("lifecycle app_open")
        trackInternal("app_open")
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc private func appDidBecomeActive() {
        sessionId = String(UUID().uuidString.prefix(8)).lowercased()
        log("lifecycle app_foreground")
        trackInternal("app_foreground")
    }

    @objc private func appWillResignActive() {
        log("lifecycle app_will_resign_active (flushing)")
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
            // 业务方若未传 appVersion 兜底为 "unknown"，避免被后端拒绝
            "app_version": appVersion.isEmpty ? "unknown" : appVersion,
            "os_version": UIDevice.current.systemVersion,
        ]
        if let userId, !userId.isEmpty { event["user_id"] = userId }
        if let properties, !properties.isEmpty { event["properties"] = properties }
        queue?.add(event)
        let pending = queue?.pendingCount ?? 0
        if let properties, !properties.isEmpty {
            log("track name=\(eventName) queue=\(pending) props=\(properties)")
        } else {
            log("track name=\(eventName) queue=\(pending)")
        }
    }

    private func log(_ msg: String) {
        if enableLog { print("[HyStatistical] \(msg)") }
    }
}
