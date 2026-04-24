import Foundation

public struct HyStatisticalConfig {
    public let apiKey: String
    public let serverUrl: String
    public let flushInterval: TimeInterval
    public let flushSize: Int
    public let maxRetries: Int
    public let enableLog: Bool

    public init(
        apiKey: String,
        serverUrl: String = "http://192.168.9.85:3000/api/v1",
        flushInterval: TimeInterval = 10,
        flushSize: Int = 50,
        maxRetries: Int = 3,
        enableLog: Bool = false
    ) {
        self.apiKey = apiKey
        self.serverUrl = serverUrl
        self.flushInterval = flushInterval
        self.flushSize = flushSize
        self.maxRetries = maxRetries
        self.enableLog = enableLog
    }
}
