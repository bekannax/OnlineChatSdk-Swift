//
//  ChatController.swift
//  OnlineChatSdk
//
//  Created by Andrew Blinov on 22/03/2019.
//  Copyright © 2019 Andrew Blinov. All rights reserved.
//

import UIKit
@preconcurrency import WebKit
import AVFoundation

@available(iOS 13.0, *)
open class ChatController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    public static let event_operatorSendMessage = "operatorSendMessage"
    public static let event_clientSendMessage = "clientSendMessage"
    public static let event_clientMakeSubscribe = "clientMakeSubscribe"
    public static let event_contactsUpdated = "contactsUpdated"
    public static let event_sendRate = "sendRate"
    public static let event_clientId = "clientId"
    public static let event_closeSupport = "closeSupport"
    
    public static let method_setClientInfo = "setClientInfo"
    public static let method_setTarget = "setTarget"
    public static let method_openReviewsTab = "openReviewsTab"
    public static let method_openTab = "openTab"
    public static let method_sendMessage = "sendMessage"
    public static let method_receiveMessage = "receiveMessage"
    public static let method_setOperator = "setOperator"
    public static let method_getContacts = "getContacts"
    private static let method_destroy = "destroy"
    private static let method_pageLoaded = "pageLoaded"

    public var chatView: WKWebView!
    private var contentController: WKUserContentController!
    private var callJs: Array<String>!
    private var didFinish: Bool = false
    private var widgetUrl: String = ""
    private var widgetOrg: String = ""
    private var css: String = ""
    private var alertLoading: UIAlertController?
    private let logTag = "OnlineChatSdk"
    private var isOnCloseSupport = false
    private let checkConnection = CheckConnection()
    
    private var scrollView: UIScrollView!
    private var webViewBottomConstraint: NSLayoutConstraint!

    private static func getUnreadedMessagesCallback(_ result: NSDictionary) -> NSDictionary {
        let resultWrapper = ChatApiMessagesWrapper(result)
        if resultWrapper.getMessages().count == 0 {
            return resultWrapper.getResult()
        }
        var unreadedMessages: Array<NSDictionary> = []
        for message: NSDictionary in resultWrapper.getMessages() as! Array<NSDictionary> {
            if message.value(forKey: "isVisibleForClient") != nil {
                if (message.value(forKey: "isVisibleForClient") as! Int) == 1 {
                    unreadedMessages.append(message)
                }
            }
        }
        if unreadedMessages.count == 0 {
            return resultWrapper.getResult()
        }
        resultWrapper.setMessages(unreadedMessages as NSArray)
        return resultWrapper.getResult()
    }

    private static func getUnreadedMessages(_ startDate: String, _ clientId: String, _ token: String, callback: @escaping (NSDictionary?) -> Void) {
        if token == "" {
            callback([
                "success": false,
                "error": [
                    "code": 0,
                    "descr": "Не задан token"
                ]
            ])
        }
        if clientId == "" {
            callback([
                "success": false,
                "error": [
                    "code": 0,
                    "descr": "Не задан clientId"
                ]
            ])
        }
        ChatApi().messages(token, params: [
            "client": [
                "clientId": clientId
            ],
            "sender": "operator",
            "status": "unreaded",
            "dateRange": [
                "start": startDate,
                "stop": ChatDateFormatter().getCurrent()
            ]
        ] as [String: Any], callback: {(result) in
            callback( ChatController.getUnreadedMessagesCallback(result!) )
        })
    }

    public static func getUnreadedMessages(clientId: String, token: String, callback: @escaping (NSDictionary?) -> Void) {
        let startDate = ChatDateFormatter().string(from: Date(timeIntervalSince1970: TimeInterval(Int(NSDate().timeIntervalSince1970) - 86400 * 14)))
        ChatController.getUnreadedMessages(startDate, clientId, token, callback: callback)
    }

    public static func getUnreadedMessages(callback: @escaping (NSDictionary?) -> Void) {
        let startDate = ChatDateFormatter().string(from: Date(timeIntervalSince1970: TimeInterval(Int(NSDate().timeIntervalSince1970) - 86400 * 14)))
        ChatController.getUnreadedMessages(startDate, ChatConfig.getClientId(), ChatConfig.getApiToken(), callback: callback)
    }

    private static func getNewMessagesCallback(_ result: NSDictionary) -> NSDictionary {
        let resultWrapper = ChatApiMessagesWrapper(result)
        if resultWrapper.getMessages().count == 0 {
            return resultWrapper.getResult()
        }
        let lastMessage = resultWrapper.getMessages()[resultWrapper.getMessages().count - 1] as! NSDictionary
        let lastDate = ChatDateFormatter().date(from: lastMessage["dateTime"] as! String)
        let nextDate = Date(timeIntervalSince1970: TimeInterval( Int(lastDate!.timeIntervalSince1970) + 1 ))
        ChatConfig.setLastDateTimeNewMessage( ChatDateFormatter().string(from: nextDate) )
        return resultWrapper.getResult()
    }

    public static func getNewMessages(clientId: String, token: String, callback: @escaping (NSDictionary?) -> Void) {
        let startDate = ChatConfig.getLastDateTimeNewMessage()
        if startDate == "" {
            self.getUnreadedMessages(clientId: clientId, token: token, callback: {(result) in
                callback( ChatController.getNewMessagesCallback(result!) )
            })
        } else {
            self.getUnreadedMessages(startDate, clientId, token, callback: {(result) in
                callback( ChatController.getNewMessagesCallback(result!) )
            })
        }
    }

    public static func getNewMessages(callback: @escaping (NSDictionary?) -> Void) {
        self.getNewMessages(clientId: ChatConfig.getClientId(), token: ChatConfig.getApiToken(), callback: {(result) in
            callback( ChatController.getNewMessagesCallback(result!) )
        })
    }
    
    public static func setInfoCustomDataValue(key: String, value: String, callback: @escaping (NSDictionary?) -> Void) {
        DispatchQueue.global().async {
            ChatApi.setInfo(
                ChatConfig.getApiToken(),
                [
                    "client": [
                        "id": ChatConfig.getClientId(),
                        "customData": [
                            key: value
                        ]
                    ],
                ] as [String : Any],
                callback: callback
            )
        }
    }

    private func initialization() {
        contentController = WKUserContentController()
        contentController.add(self, name: "chatInterface")

        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.preferences = preferences
        // config.mediaPlaybackRequiresUserAction = false
        config.allowsInlineMediaPlayback = true
        if !isResizeByKeyboard() {
            var frame = UIScreen.main.bounds
            if parent != nil && parent?.view != nil && parent?.view.bounds != nil {
                frame = (parent?.view.bounds)!
            }
            chatView = WKWebView(frame: frame, configuration: config)
            view = chatView
        } else {
            view = UIView()
            chatView = WKWebView(frame: .zero, configuration: config)
            chatView.translatesAutoresizingMaskIntoConstraints = false
//            view = chatView
            view.addSubview(chatView)
            view.backgroundColor = .white
            NSLayoutConstraint.activate([
                chatView.topAnchor.constraint(equalTo: view.topAnchor),
                chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            webViewBottomConstraint = chatView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            webViewBottomConstraint.isActive = true
            chatView.scrollView.isScrollEnabled = false
        }

        chatView.scrollView.bounces = false
        chatView.navigationDelegate = self
    }
    
    override public func loadView() {
        initialization()
        setupKeyboardObservers()
        
        // print("\(logTag) :: loadView")
    }
    
    private func setupKeyboardObservers() {
        if !isResizeByKeyboard() {
            return
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        if !isResizeByKeyboard() {
            return
        }
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let keyboardHeight = view.bounds.height - keyboardFrame.origin.y + getKeyboardPadding()
        
        UIView.animate(withDuration: duration) {
            if keyboardHeight > 0 {
                // Клавиатура появляется
                self.webViewBottomConstraint.constant = -keyboardHeight + self.view.safeAreaInsets.bottom
            } else {
                // Клавиатура скрывается
                self.webViewBottomConstraint.constant = 0
            }
            self.view.layoutIfNeeded()
        }
    }
        
    private func getAlertLoadingActionCloseTitle() -> String {
        let currentLanguage = Locale.current.languageCode
        if currentLanguage == "ru" {
            return "Закрыть"
        }
        return "Close"
    }
    
    private func showLoadingDialog() {
        if alertLoading != nil {
            return
        }
        alertLoading = UIAlertController(
            title: nil,
            message: " ",
            preferredStyle: .alert
        )
        alertLoading?.addAction(UIAlertAction(title: getAlertLoadingActionCloseTitle(), style: .destructive, handler: cancelLoading))
        
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()

        alertLoading?.view.addSubview(loadingIndicator)
        
        var constant: CGFloat = -60.0
        if #available(iOS 26.0, *) {
            constant = -80.0
        }
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: alertLoading!.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: alertLoading!.view.bottomAnchor, constant: constant)
        ])
        present(alertLoading!, animated: true)
    }
                        
    private func cancelLoading(action: UIAlertAction) {
        onCloseSupport()
    }

    private func hideLoadingDialog() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.alertLoading == nil {
                return
            }
            self.alertLoading?.dismiss(animated: true, completion: nil)
            self.alertLoading = nil
        }
    }


    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showLoadingDialog()
        print("\(logTag) :: webView :: didStartProvisionalNavigation")
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideLoadingDialog()
        showMessage(error.localizedDescription)
        print("\(logTag) :: webView :: didFail")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        hideLoadingDialog()
        showMessage(error.localizedDescription)
        print("\(logTag) :: webView :: didFailProvisionalNavigation")
    }
    
    private func showMessage(_ message: String) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.onCloseSupport()
        })
        present(alert, animated: true, completion: nil)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinish = true
        if callJs != nil && !callJs.isEmpty {
            for script in callJs {
                callJs(script)
            }
            callJs = nil
        }
        print("\(logTag) :: webView :: didFinish")
//        hideLoadingDialog()
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> ()) {
        if navigationAction.request.url == nil {
            print("\(logTag) :: webView :: navigationAction :: 0")
            decisionHandler(.cancel)
            return
        }
        if let _ = navigationAction.request.url?.host {
            if (navigationAction.request.url?.absoluteString.contains(self.widgetOrg))! {
                print("\(logTag) :: webView :: navigationAction :: 1 :: \(navigationAction.request.url!)")
                decisionHandler(.allow)
                return
            }
            if (navigationAction.request.url?.absoluteString.contains(self.widgetUrl))! {
                print("\(logTag) :: webView :: navigationAction :: 2 :: \(navigationAction.request.url!)")
                decisionHandler(.allow)
                return
            }
            if (
                (navigationAction.request.url?.absoluteString.contains( "https://www.google.com/recaptcha/api2/anchor?" ))! ||
                (navigationAction.request.url?.absoluteString.contains( "https://www.google.com/recaptcha/api/fallback?" ))! ||
                (navigationAction.request.url?.absoluteString.contains( "https://www.google.com/recaptcha/api2/bframe?" ))!
            ) {
                print("\(logTag) :: webView :: navigationAction :: 3 :: \(navigationAction.request.url!)")
                decisionHandler(.allow)
                return
            }
        }
        print("\(logTag) :: webView :: navigationAction :: 3 :: \(navigationAction.request.url!)")
        decisionHandler(.cancel)
        onLinkPressed(url: navigationAction.request.url!)
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
        print("\(logTag) :: callJs :: \(script)")
        chatView.evaluateJavaScript(script)
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
    
//    public func load(_ id: String, _ domain: String, _ language: String = "", _ clientId: String = "", _ apiToken: String = "", _ showCloseButton: Bool = true, css: String = "") {
//        if apiToken != "" {
//            ChatConfig.setApiToken(apiToken)
//        }
//        var setup: Dictionary<String, Any> = [:]
//        if !language.isEmpty {
//            setup["language"] = language
//        }
//        if !clientId.isEmpty {
//            setup["clientId"] = clientId
//        }
//        widgetUrl = "https://admin.verbox.ru/support/chat/\(id)/\(domain)"
//        self.css = css
//        var url = URL(string: widgetUrl)
//        if url == nil {
//            var encodeDomain = String(describing: domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
//            encodeDomain = encodeDomain.replacingOccurrences(of: "Optional(\"", with: "")
//            encodeDomain = encodeDomain.replacingOccurrences(of: "\")", with: "")
//            widgetUrl = "https://admin.verbox.ru/support/chat/\(id)/\(encodeDomain)"
//            url = URL(string: widgetUrl)
//        }
//        var urlComponents = URLComponents(url: url!, resolvingAgainstBaseURL: false)
//        if !setup.isEmpty {
//            if (showCloseButton) {
//                urlComponents?.queryItems = [
//                    URLQueryItem(name: "setup", value: toJson(setup as AnyObject)),
//                    URLQueryItem(name: "sdk-show-close-button", value: "1")
//                ]
//            } else {
//                urlComponents?.queryItems = [
//                    URLQueryItem(name: "setup", value: toJson(setup as AnyObject))
//                ]
//            }
//        } else {
//            if (showCloseButton) {
//                urlComponents?.queryItems = [
//                    URLQueryItem(name: "sdk-show-close-button", value: "1")
//                ]
//            }
//        }
//        url = urlComponents!.url!
//        if url == nil {
//            url = URL(string: widgetUrl)
//        }
//        chatView.load(URLRequest(url: url!))
//        chatView.allowsBackForwardNavigationGestures = true
//    }
    
    
    public func load(_ id: String, _ domain: String, _ language: String = "", _ clientId: String = "", _ apiToken: String = "", _ showCloseButton: Bool = true, css: String = "") {
        showLoadingDialog()
        Task {
            print("\(logTag) :: load :: 1")
            if apiToken != "" {
                ChatConfig.setApiToken(apiToken)
            }
            var setup: Dictionary<String, Any> = [:]
            if !language.isEmpty {
                setup["language"] = language
            }
            if !clientId.isEmpty {
                setup["clientId"] = clientId
            }
            self.css = css
            var encodeDomain: String = String(describing: domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
            if encodeDomain.contains("Optional(\"") {
                encodeDomain = encodeDomain.replacingOccurrences(of: "Optional(\"", with: "")
                encodeDomain = encodeDomain.replacingOccurrences(of: "\")", with: "")
            }

            let domain = await self.checkConnection.getDomain()
            
            widgetUrl = "https://\(domain)/support/chat/\(id)/\(encodeDomain)"
            widgetOrg = "https://\(domain)/support/chat/\(id)/"
            var url = URL(string: widgetUrl)
            if url != nil {
                var urlComponents = URLComponents(url: url!, resolvingAgainstBaseURL: false)
                if !setup.isEmpty {
                    if (showCloseButton) {
                        urlComponents?.queryItems = [
                            URLQueryItem(name: "setup", value: toJson(setup as AnyObject)),
                            URLQueryItem(name: "sdk-show-close-button", value: "1")
                        ]
                    } else {
                        urlComponents?.queryItems = [
                            URLQueryItem(name: "setup", value: toJson(setup as AnyObject))
                        ]
                    }
                } else {
                    if (showCloseButton) {
                        urlComponents?.queryItems = [
                            URLQueryItem(name: "sdk-show-close-button", value: "1")
                        ]
                    }
                }
                url = urlComponents!.url
            }
            if url == nil {
                url = URL(string: widgetUrl)
            }
            if url == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.showMessage("url=\(self.widgetUrl) not init")
                }
                return
            }
            chatView.load(URLRequest(url: url!))
            chatView.allowsBackForwardNavigationGestures = true
            print("\(logTag) :: load :: 2")
        }
    }
    
    public func injectCss(style: String) {
        if (style.isEmpty) {
          return;
        }

        let injectCssTemplate = "(function() {" +
            "var parent = document.getElementsByTagName('head').item(0);" +
            "var style = document.createElement('style');" +
            "style.type = 'text/css';" +
            "style.innerHTML = '\(style)';" +
            "parent.appendChild(style) ;" +
        "})()";
        
        callJs(injectCssTemplate);
      }
    
    public func callJsMethod(_ name: String, params: Array<Any>) {
        if didFinish {
            callJs(getCallJsMethod(name, params: params))
        } else {
            if callJs == nil {
                callJs = []
            }
            callJs.append(getCallJsMethod(name, params: params))
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

    private func callJsDestroy() {
        print("\(logTag) :: callJsDestroy")
        callJsMethod(ChatController.method_destroy, params: [])
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        hideLoadingDialog()
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
        if chatView == nil {
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
            case ChatController.method_pageLoaded:
                injectCss(style: self.css)
                onChatWasOpen()
                listenApplicationState()
                break
            case ChatController.event_closeSupport:
                onCloseSupport()
                break
            case ChatController.event_clientId:
                let clientId = data!["clientId"] != nil ? data!["clientId"] as! String : ""
                ChatConfig.setClientId(clientId)
                onClientId(clientId)
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
        print("\(logTag) :: userContentController :: \(data!)")
        onEvent(name, data!)
    }
    
    private func listenApplicationState() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        onChatWasOpen()
    }

    @objc private func appWillResignActive() {
        onChatWasClosed()
    }
    
    open func isResizeByKeyboard() -> Bool {
        return false
    }
    
    open func getKeyboardPadding() -> CGFloat {
        return 34.0
    }
    
    open func onChatWasOpen() {
        
    }
    
    open func onChatWasClosed() {
        
    }
    
    open func onCloseSupport() {
        if (isOnCloseSupport) {
            return
        }
        isOnCloseSupport = true
        print("\(logTag) :: onCloseSupport :: 1")
        if chatView == nil {
            return
        }
        print("\(logTag) :: onCloseSupport :: 2")
        
        contentController.removeScriptMessageHandler(forName: "chatInterface")
        contentController.removeAllUserScripts()
        
        chatView.stopLoading()
        callJsDestroy()
        contentController = nil
        chatView = nil
        
        dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: true)
        NotificationCenter.default.removeObserver(self)
        
        onChatWasClosed()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            onCloseSupport()
        }
        print("\(logTag) :: viewDidDisappear")
    }

    open func onLinkPressed(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
        playSound(1315)
    }
    
    open func onEvent(_ name: String, _ data: NSDictionary) {
        
    }
    
    open func getContactsCallback(_ data: NSDictionary) {
        
    }
}
