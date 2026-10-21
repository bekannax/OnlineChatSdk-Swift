//
//  ChatApi.swift
//  OnlineChatSdk
//
//  Created by Andrew Blinov on 17.10.2026.
//

import Foundation

class ChatApi {

    private let orgId: String
    private let siteId: String
    private let clientId: String

    private let apiUrl = "https://%@/comet/%@?orgId=%@&siteId=%@&clientId=%@"

    init() {
        self.orgId = ChatConfig.getOrgId()
        self.siteId = ChatConfig.getSiteId()
        self.clientId = ChatConfig.getClientId()
    }

    private func requestGet(_ sUrl: String, completion: @escaping (ChatApiResponseModel) -> Void) {
        guard let url = URL(string: sUrl) else {
            completion(ChatApiResponseModel(error: ChatApiResponseErrorModel(code: 0, descr: "URL failed: invalid URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Ошибка сети / URL
            if let error = error {
                completion(ChatApiResponseModel(
                    error: ChatApiResponseErrorModel(code: 0, descr: "URL failed: \(error.localizedDescription)")
                ))
                return
            }

            // Проверка HTTP-статуса
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(ChatApiResponseModel(
                    error: ChatApiResponseErrorModel(code: 0, descr: "empty response :: response == nil")
                ))
                return
            }

            guard httpResponse.statusCode == 200 else {
                completion(ChatApiResponseModel(
                    error: ChatApiResponseErrorModel(
                        code: httpResponse.statusCode,
                        descr: "HTTP error code: \(httpResponse.statusCode)"
                    )
                ))
                return
            }

            // Проверка тела ответа
            guard let data = data else {
                completion(ChatApiResponseModel(
                    error: ChatApiResponseErrorModel(code: 0, descr: "empty response :: data == nil")
                ))
                return
            }

            let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            completion(ChatApiResponseModel(result: text))
        }

        task.resume()
    }

    private func checkAuthParams() -> ChatApiResponseErrorModel? {
        var error = ""
        if orgId.isEmpty {
            error = "orgId.isEmpty() "
        }
        if siteId.isEmpty {
            error += "siteId.isEmpty() "
        }
        if clientId.isEmpty {
            error += "clientId.isEmpty()"
        }
        if error.isEmpty {
            return nil
        }
        return ChatApiResponseErrorModel(code: 0, descr: "auth params not init: \(error)")
    }

    public func getClientUnreadMessageCount(completion: @escaping (ChatApiGetClientUnreadMessageCountResponseModel) -> Void) {
        if let authError = checkAuthParams() {
            completion(ChatApiGetClientUnreadMessageCountResponseModel(error: authError))
            return
        }

        // "https://%@/comet/%@?orgId=%@&siteId=%@&clientId=%@"
        // https://widget.apibcknd.com/comet/getClientUnreadMessageCount?orgId=&siteId=&clientId=
        Task {
            let url = String(
                format: apiUrl,
                await CheckConnection().getApiDomain(),
                "getClientUnreadMessageCount",
                orgId,
                siteId,
                clientId
            )
            print("chatapi :: ")

            requestGet(url) { response in
                if let error = response.error {
                    completion(ChatApiGetClientUnreadMessageCountResponseModel(error: error))
                    return
                }

                if response.result.isEmpty {
                    completion(ChatApiGetClientUnreadMessageCountResponseModel(result: 0))
                    return
                }

                if let count = Int(response.result) {
                    completion(ChatApiGetClientUnreadMessageCountResponseModel(result: count))
                } else {
                    completion(ChatApiGetClientUnreadMessageCountResponseModel(
                        error: ChatApiResponseErrorModel(
                            code: 0,
                            descr: "failed to parse result: \(response.result)"
                        )
                    ))
                }
            }
        }
    }
}
