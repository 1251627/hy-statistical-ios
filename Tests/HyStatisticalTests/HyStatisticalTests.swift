import XCTest
@testable import HyStatistical

final class HyStatisticalTests: XCTestCase {
    func testConfigDefaults() {
        let config = HyStatisticalConfig(
            apiKey: "test_key",
            serverUrl: "https://example.test/api/v1"
        )
        XCTAssertEqual(config.apiKey, "test_key")
        XCTAssertEqual(config.serverUrl, "https://example.test/api/v1")
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

final class HyAdFingerprintTests: XCTestCase {

    func testCollectReturnsIosOs() {
        let fp = HyAdFingerprint.collect()
        XCTAssertEqual(fp.os, "ios")
    }

    func testPaidIsThreeMd5Hashes() {
        let fp = HyAdFingerprint.collect()
        let parts = fp.paid.split(separator: "-")
        XCTAssertEqual(parts.count, 3)
        let hexRegex = #"^[0-9a-f]+$"#
        for part in parts {
            XCTAssertEqual(part.count, 32, "each MD5 component should be 32 hex chars")
            XCTAssertNotNil(part.range(of: hexRegex, options: .regularExpression),
                            "should be lowercase hex: \(part)")
        }
    }

    func testIdfaIsLowercaseUuidOrEmpty() {
        let fp = HyAdFingerprint.collect()
        if !fp.idfa.isEmpty {
            XCTAssertTrue(fp.idfa.range(of: #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#,
                                       options: .regularExpression) != nil,
                         "got: \(fp.idfa)")
        }
    }

    func testPaidStableAcrossCalls() {
        let a = HyAdFingerprint.collect().paid
        let b = HyAdFingerprint.collect().paid
        XCTAssertEqual(a, b, "PAID should be stable within a single boot")
    }

    func testIdfvIsLowercaseUuidOrEmpty() {
        // IDFV via UIDevice.identifierForVendor — may be nil in some test contexts → "".
        // When non-empty, should be a lowercase UUID. iOS Simulator returns a stable UUID.
        let fp = HyAdFingerprint.collect()
        if !fp.idfv.isEmpty {
            XCTAssertTrue(
                fp.idfv.range(of: #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#,
                              options: .regularExpression) != nil,
                "got: \(fp.idfv)"
            )
        }
    }

    func testIdfvStableAcrossCalls() {
        // IDFV must be stable within a single app process lifecycle.
        let a = HyAdFingerprint.collect().idfv
        let b = HyAdFingerprint.collect().idfv
        XCTAssertEqual(a, b, "IDFV should be stable across calls within the same boot")
    }
}
