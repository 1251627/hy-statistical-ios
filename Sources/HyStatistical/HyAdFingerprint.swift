import Foundation
import AdSupport
import CryptoKit
import Darwin

/// Fingerprint payload mailed to the backend in the `device_fingerprint` field
/// of the `/api/v1/collect` envelope.
public struct HyAdFingerprintData {
    public let os: String          // "ios"
    public let idfa: String        // "" if all-zero (unauthorized) — backend treats as absent
    public let paid: String        // 32-hex MD5 triple separated by "-"
    public let ua: String          // "" on iOS apps (no useful value)
}

public enum HyAdFingerprint {
    /// Returns nil only if AdSupport is unavailable (extremely rare).
    public static func collect() -> HyAdFingerprintData {
        let idfa = readIdfa()
        let paid = computePaid()
        return HyAdFingerprintData(
            os: "ios",
            idfa: idfa.isAllZero ? "" : idfa,
            paid: paid,
            ua: ""
        )
    }

    /// Reads IDFA without prompting ATT. Returns "00000000-...-0000" when unauthorized.
    private static func readIdfa() -> String {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString.lowercased()
    }

    /// PAID = md5(installTime) + "-" + md5(systemUpdateTime) + "-" + md5(bootTime)
    /// Each component is the unix seconds (UInt64) interpreted as a UTF-8 string.
    private static func computePaid() -> String {
        let install = secondsToMD5(installTime())
        let sysupd  = secondsToMD5(systemUpdateTime())
        let boot    = secondsToMD5(bootTime())
        return "\(install)-\(sysupd)-\(boot)"
    }

    private static func installTime() -> UInt64 {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        guard let path = libraryURL?.path,
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let date = attrs[.creationDate] as? Date else {
            return 0
        }
        return UInt64(date.timeIntervalSince1970)
    }

    private static func systemUpdateTime() -> UInt64 {
        // `/usr/lib` mtime is bumped on OS updates; sandboxed apps can stat it.
        var st = stat()
        guard stat("/usr/lib", &st) == 0 else { return 0 }
        return UInt64(st.st_mtimespec.tv_sec)
    }

    private static func bootTime() -> UInt64 {
        var tv = timeval()
        var size = MemoryLayout<timeval>.size
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        guard sysctl(&mib, 2, &tv, &size, nil, 0) == 0 else { return 0 }
        return UInt64(tv.tv_sec)
    }

    private static func secondsToMD5(_ s: UInt64) -> String {
        let str = String(s)
        let digest = Insecure.MD5.hash(data: Data(str.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension String {
    /// True when the string is "00000000-0000-0000-0000-000000000000" (case-insensitive).
    var isAllZero: Bool {
        return self == "00000000-0000-0000-0000-000000000000"
    }
}
