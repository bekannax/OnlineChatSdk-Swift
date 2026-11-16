//
//  JsCommand.swift
//  OnlineChatSdk
//
//  Created by Andrew Blinov on 13.11.2026.
//

public struct JsCommand {
    let script: String
    let arguments: [String: Any]
    let completionHandler: (@MainActor @Sendable (Result<Any, any Error>) -> Void)?
    
    init(_ script: String, _ arguments: [String: Any], _ completionHandler: (@MainActor @Sendable (Result<Any, any Error>) -> Void)?) {
        self.script = script
        self.arguments = arguments
        self.completionHandler = completionHandler
    }
}
