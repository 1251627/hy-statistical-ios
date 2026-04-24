import Foundation

final class HyEventQueue {
    private let serverUrl: String
    private let apiKey: String
    private let flushSize: Int
    private let maxRetries: Int
    private let enableLog: Bool

    private var queue: [[String: Any]] = []
    private var timer: Timer?
    private var isFlushing = false
    private let lock = NSLock()

    private static let offlineKey = "hy_statistical_offline_events"

    init(serverUrl: String, apiKey: String, flushSize: Int, flushInterval: TimeInterval, maxRetries: Int, enableLog: Bool = false) {
        self.serverUrl = serverUrl
        self.apiKey = apiKey
        self.flushSize = flushSize
        self.maxRetries = maxRetries
        self.enableLog = enableLog

        restoreOfflineEvents()

        timer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }

    func add(_ event: [String: Any]) {
        lock.lock()
        queue.append(event)
        let shouldFlush = queue.count >= flushSize
        lock.unlock()
        if shouldFlush { flush() }
    }

    func flush() {
        lock.lock()
        guard !isFlushing, !queue.isEmpty else { lock.unlock(); return }
        isFlushing = true
        let batchCount = min(flushSize, queue.count)
        let batch = Array(queue.prefix(batchCount))
        lock.unlock()

        log("flush → POST \(serverUrl)/collect batch=\(batch.count)")

        send(batch: batch, attempt: 0) { [weak self] success in
            guard let self else { return }
            self.lock.lock()
            if success {
                self.queue.removeFirst(batchCount)
                self.clearOfflineCache()
            } else {
                self.log("flush GIVE UP, saving \(self.queue.count) events offline")
                self.saveOfflineEvents()
            }
            self.isFlushing = false
            self.lock.unlock()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        saveOfflineEvents()
    }

    var pendingCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return queue.count
    }

    private func send(batch: [[String: Any]], attempt: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverUrl)/collect") else {
            log("flush FAIL invalid URL: \(serverUrl)/collect")
            completion(false); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        do { request.httpBody = try JSONSerialization.data(withJSONObject: ["events": batch]) }
        catch {
            log("flush FAIL JSON encode error: \(error)")
            completion(false); return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error == nil, statusCode == 200 {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                self.log("flush OK \(body)")
                completion(true)
            } else {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                let errDesc = error.map { "\($0)" } ?? "nil"
                self.log("flush FAIL attempt=\(attempt + 1)/\(self.maxRetries) status=\(statusCode) error=\(errDesc) body=\(body)")
                if attempt < self.maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt))
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.send(batch: batch, attempt: attempt + 1, completion: completion)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }

    private func saveOfflineEvents() {
        guard !queue.isEmpty else { return }
        if let data = try? JSONSerialization.data(withJSONObject: queue) {
            UserDefaults.standard.set(data, forKey: Self.offlineKey)
            log("saved \(queue.count) events offline")
        }
    }

    private func restoreOfflineEvents() {
        guard let data = UserDefaults.standard.data(forKey: Self.offlineKey),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        queue.append(contentsOf: array)
        UserDefaults.standard.removeObject(forKey: Self.offlineKey)
        log("restored \(array.count) events from offline cache")
    }

    private func clearOfflineCache() {
        UserDefaults.standard.removeObject(forKey: Self.offlineKey)
    }

    private func log(_ msg: String) {
        if enableLog { print("[HyStatistical] \(msg)") }
    }
}
