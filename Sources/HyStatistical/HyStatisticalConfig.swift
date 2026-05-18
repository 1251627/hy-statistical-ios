import Foundation

public struct HyStatisticalConfig {
    public let apiKey: String
    public let serverUrl: String
    public let flushInterval: TimeInterval
    public let flushSize: Int
    public let maxRetries: Int
    public let enableLog: Bool
    /// 是否启用广告归因（采集 IDFA + PAID 并上报为 device_fingerprint）。
    /// 开启后请同步更新 App 的隐私政策与 Info.plist（NSUserTrackingUsageDescription），
    /// 详见 `PRIVACY_NOTICE_TEMPLATE.md`。默认关闭。
    public let enableAdAttribution: Bool

    /// `serverUrl` 必填，例如 https://collect.your-domain.com/api/v1
    /// 业务方在每次集成时显式声明，避免误把开发地址带到生产。
    public init(
        apiKey: String,
        serverUrl: String,
        flushInterval: TimeInterval = 10,
        flushSize: Int = 50,
        maxRetries: Int = 3,
        enableLog: Bool = false,
        enableAdAttribution: Bool = false
    ) {
        self.apiKey = apiKey
        self.serverUrl = serverUrl
        self.flushInterval = flushInterval
        self.flushSize = flushSize
        self.maxRetries = maxRetries
        self.enableLog = enableLog
        self.enableAdAttribution = enableAdAttribution
    }
}
