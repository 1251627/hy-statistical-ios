import XCTest
@testable import HyStatistical

final class HyStatisticalTests: XCTestCase {
    func testConfigDefaults() {
        let config = HyStatisticalConfig(apiKey: "test_key")
        XCTAssertEqual(config.apiKey, "test_key")
        XCTAssertEqual(config.serverUrl, "http://192.168.9.85:3000/api/v1")
        XCTAssertEqual(config.flushInterval, 10)
        XCTAssertEqual(config.flushSize, 50)
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertFalse(config.enableLog)
    }

    func testConfigCustomValues() {
        let config = HyStatisticalConfig(
            apiKey: "my_key",
            serverUrl: "https://example.com/api/v1",
            flushInterval: 30,
            flushSize: 100,
            maxRetries: 5
        )
        XCTAssertEqual(config.serverUrl, "https://example.com/api/v1")
        XCTAssertEqual(config.flushSize, 100)
    }
}
