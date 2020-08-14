//
//  ChatApi.swift
//  OnlineChatSdk
//
//  Created by Andrew Blinov on 29/03/2019.
//  Copyright © 2019 Andrew Blinov. All rights reserved.
//

import Foundation

open class ChatApi {
    
    private func post(_ url: String, _ params: Dictionary<String, Any>, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else { return }
        request.httpBody = httpBody
        
        let session = URLSession.shared
        session.dataTask(with: request, completionHandler: completionHandler).resume()
    }
    
    public func send(_ token: String, _ method: String, _ params: Dictionary<String, Any>, callback: @escaping (NSDictionary?) -> Void) {
        let url = "https://admin.verbox.ru/api/chat/\(token)/\(method)"
        post(url, params) { (data, response, error) in
            guard let data = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                callback(json)
            } catch {}
        }
    }
    
    public func messages(_ token: String, params: Dictionary<String, Any>, callback: @escaping (NSDictionary?) -> Void) {
        send(token, "message", params, callback: callback)
    }


    public static func getNewMessages(_ token: String, _ clientId: String, callback: @escaping (NSDictionary?) -> Void) {
        let dtFormatter = DateFormatter()
        dtFormatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        dtFormatter.locale = Locale(identifier: "en")
        dtFormatter.dateFormat = "yyyy'-'MM'-'dd'"
        dtFormatter.timeZone = TimeZone(secondsFromGMT: 10800)
        
        let params = [
            "client": ["clientId": clientId],
            "sender": "operator",
            "status": "unreaded",
            "dateRange": ["start": dtFormatter.string(from: Date(timeIntervalSince1970: Date().timeIntervalSince1970  - 86400 * 14)), "stop": dtFormatter.string(from: Date())]
            ] as [String : Any]
        (ChatApi()).messages(token, params: params, callback: callback)
    }
}
