//
//  ChatController.swift
//  OnlineChatSdk
//
//  Created by Andrew Blinov on 22/03/2019.
//  Copyright © 2019 Andrew Blinov. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation

open class ChatController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    public static let event_operatorSendMessage = "operatorSendMessage";
    public static let event_clientSendMessage = "clientSendMessage";
    public static let event_clientMakeSubscribe = "clientMakeSubscribe";
    public static let event_contactsUpdated = "contactsUpdated";
    public static let event_sendRate = "sendRate";
    public static let event_clientId = "clientId";
    
    public static let method_setClientInfo = "setClientInfo";
    public static let method_setTarget = "setTarget";
    public static let method_openReviewsTab = "openReviewsTab";
    public static let method_openTab = "openTab";
    public static let method_sendMessage = "sendMessage";
    public static let method_receiveMessage = "receiveMessage";
    public static let method_setOperator = "setOperator";
    public static let method_getContacts = "getContacts";
    
    public var chatView: WKWebView!
    private var callJs: Array<String>!
    private var didFinish: Bool = false
    private var widgetUrl: String = ""
        
    override public func loadView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "chatInterface")

        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences = preferences


        var frame = UIScreen.main.bounds
        if self.parent != nil && self.parent?.view != nil && self.parent?.view.bounds != nil {
            frame = (self.parent?.view.bounds)!
        }
        self.chatView = WKWebView(frame: frame, configuration: config)
        self.chatView.navigationDelegate = self
        self.view = self.chatView

    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.didFinish = true
        if self.callJs != nil && !self.callJs.isEmpty {
            for script in self.callJs {
                callJs(script)
            }
            self.callJs = nil
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> ()) {
        if let _ = navigationAction.request.url?.host {
            if navigationAction.request.url?.absoluteString == self.widgetUrl {
                decisionHandler(.allow)
                return
            }
        }
        decisionHandler(.cancel)
        self.onLinkPressed(url: navigationAction.request.url!)
    }

    private func getCallJsMethod(_ name: String, params: Array<Any>) -> String {
        var res: String = "window.MeTalk('"
        res.append(name)
        res.append("'")
        if params.count > 0 {
            for p in params {
                res.append(",")
                if p is Int {
                    res.append(String(describing: p))
                } else if p is Command {
                    res.append((p as! Command).command)
                } else {
                    res.append("'")
                    res.append(String(describing: p))
                    res.append("'")
                }
            }
        }
        res.append(")")
        return res
    }
    
    private func callJs(_ script: String) {
        self.chatView.evaluateJavaScript(script)
    }
    
    private func toJson(_ jsonObj: AnyObject) -> String {
        var data:Data? = nil
        do {
            data = try JSONSerialization.data(withJSONObject: jsonObj, options: JSONSerialization.WritingOptions());
        } catch {}
        if data != nil {
            return NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
        }
        return "{}"
    }
    
    public func load(_ id: String, _ domain: String, _ language: String = "", _ clientId: String = "") {
        var setup: Dictionary<String, Any> = [:]
        if !language.isEmpty {
            setup["language"] = language
        }
        if !clientId.isEmpty {
            setup["clientId"] = clientId
        }
        self.widgetUrl = "https://admin.verbox.ru/support/chat/\(id)/\(domain)"
        var url = URL(string: self.widgetUrl)
        if !setup.isEmpty {
            var urlComponents = URLComponents(url: url!, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = [URLQueryItem(name: "setup", value: toJson(setup as AnyObject))]
            url = urlComponents!.url!
        }
        if url == nil {
            url = URL(string: self.widgetUrl)
        }

        self.chatView.load(URLRequest(url: url!))
        self.chatView.allowsBackForwardNavigationGestures = true
    }
    
    public func callJsMethod(_ name: String, params: Array<Any>) {
        if self.didFinish {
            callJs(getCallJsMethod(name, params: params))
        } else {
            if self.callJs == nil {
                self.callJs = []
            }
            self.callJs.append(getCallJsMethod(name, params: params))
        }
    }
    
    public func callJsSetClientInfo(_ jsonInfo: String) {
        callJsMethod(ChatController.method_setClientInfo, params: [Command(jsonInfo)])
    }
    
    public func callJsSetTarget(_ reason: String) {
        callJsMethod(ChatController.method_setTarget, params: [reason])
    }
    
    public func callJsOpenReviewsTab() {
        callJsMethod(ChatController.method_openReviewsTab, params: [])
    }
    
    public func callJsOpenTab(_ index: Int) {
        callJsMethod(ChatController.method_openTab, params: [index])
    }
    
    public func callJsSendMessage(_ text: String) {
        callJsMethod(ChatController.method_sendMessage, params: [text])
    }
    
    public func callJsReceiveMessage(_ text: String, _ oper: String, _ simulateTyping: Int) {
        callJsMethod(ChatController.method_receiveMessage, params: [text, oper, simulateTyping])
    }
    
    public func callJsSetOperator(_ login: String) {
        callJsMethod(ChatController.method_setOperator, params: [login])
    }
    
    public func callJsGetContacts() {
        callJsMethod(ChatController.method_getContacts, params: [Command("window.getContactsCallback")])
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name != "chatInterface" {
            return
        }

        let jsonBody = (message.body as! String).data(using: .utf8)!
        let body = try? (JSONSerialization.jsonObject(with: jsonBody, options: .mutableLeaves) as! NSDictionary)
        if body == nil {
            return
        }
        
        if body!["name"] == nil {
            return
        }
        var data: NSDictionary?
        if body!["data"] != nil {
            data = (body!["data"] as! NSDictionary)
        } else {
            data = [:]
        }
        let name = body!["name"] as! String
        switch name {
            case ChatController.event_clientId:
                onClientId(data!["clientId"] != nil ? data!["clientId"] as! String : "")
                break
            case ChatController.event_sendRate:
                onSendRate(data!)
                break
            case ChatController.event_contactsUpdated:
                onContactsUpdated(data!)
                break
            case ChatController.event_clientSendMessage:
                onClientSendMessage(data!)
                break
            case ChatController.event_clientMakeSubscribe:
                onClientMakeSubscribe(data!)
                break
            case ChatController.event_operatorSendMessage:
                onOperatorSendMessage(data!)
                break
            case ChatController.method_getContacts:
                getContactsCallback(data!)
                break
            default:
                break
        }
        onEvent(name, data!)
    }


    open func onLinkPressed(url: URL) {
        UIApplication.shared.openURL(url)
    }
    
    open func playSound(_ systemSoundId: SystemSoundID) {
        AudioServicesPlaySystemSound(systemSoundId)
    }
    
    open func onClientId(_ clientId: String) {
        
    }
    
    open func onSendRate(_ data: NSDictionary) {
        
    }
    
    open func onContactsUpdated(_ data: NSDictionary) {
        
    }
    
    open func onClientSendMessage(_ data: NSDictionary) {
        
    }
    
    open func onClientMakeSubscribe(_ data: NSDictionary) {
        
    }
    
    open func onOperatorSendMessage(_ data: NSDictionary) {
        self.playSound(1315)
    }
    
    open func onEvent(_ name: String, _ data: NSDictionary) {
        
    }
    
    open func getContactsCallback(_ data: NSDictionary) {
        
    }
}
