import Foundation

class CheckConnection {
    
    private var tasks: [Task<String, Error>] = []
    private let lock = NSLock()
    private let check = "https://operator.me-talk.ru/cabinet/assets/operatorApplication/checkConnection.json"
    private let checkAlternative = "https://operator.verbox.me/cabinet/assets/operatorApplication/checkConnection.json"
    private var needUseAlternativeUrl: Bool? = nil
    
    func getDomain() async -> String {
        let resultNeedUseAlternativeUrl = await isNeedUseAlternativeUrl()
        if resultNeedUseAlternativeUrl {
            return "admin.verbox.me"
        }
        return "admin.verbox.ru"
    }
    
    func isNeedUseAlternativeUrl() async -> Bool {
        if needUseAlternativeUrl != nil {
            return needUseAlternativeUrl!
        }
        guard let checkUrl = URL(string: check),
              let checkAlternativeUrl = URL(string: checkAlternative) else {
            return false
        }
        let sUrl = try? await requestsAsync(urls: [checkUrl, checkAlternativeUrl])
        if sUrl == nil {
            return false
        } else if sUrl!.contains(check) {
            needUseAlternativeUrl = false
            return false
        } else if sUrl!.contains(checkAlternative) {
            needUseAlternativeUrl = true
            return true
        }
        return false
    }
    
    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        cancelAllTasks()
    }
    
    private func requestsAsync(urls: [URL]) async throws -> String {
        for url in urls {
            let task = Task<String, Error> {
                var result: String = ""
                try Task.checkCancellation()
                var request = URLRequest(url: url, timeoutInterval: 2.0)
                request.httpMethod = "GET"
                request.addValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
                do {
                    let (_, response) = try await URLSession.shared.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        try Task.checkCancellation()
                        return ""
                    }
                    if httpResponse.statusCode == 200 {
                        result = httpResponse.url?.absoluteString ?? ""
                    } else {
                        result = ""
                    }
                } catch {
                    result = ""
                }
                try Task.checkCancellation()
//                if result.contains(check) {
//                    result = ""
//                }
                return result
            }
            tasks.append(task)
        }
        
        return try await withThrowingTaskGroup(of: String.self) { group in
            for task in tasks {
                group.addTask {
                    return try await task.value
                }
            }
            
            guard let result = try await group.next() else {
                return ""
            }
            if !result.isEmpty {
                cancelAllTasks()
                group.cancelAll()
                return result
            } else {
                guard let result = try await group.next() else {
                    return ""
                }
                cancelAllTasks()
                group.cancelAll()
                return result
            }
        }
    }
    
    private func cancelAllTasks() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }
}
