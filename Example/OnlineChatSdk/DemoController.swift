//
//  DemoController.swift
//  OnlineChatSdk_Example
//
//  Created by Andrew Blinov on 16.11.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import WebKit
import OnlineChatSdk

class DemoController: ChatController {
    
    override func viewDidLoad() {
            super.viewDidLoad()
            load("593adecd804fc4e32e7e865d659f2356", "me-talk.ru")
        }
        
        override func onClientId(_ clientId: String) {
            
        }

        override func onSendRate(_ data: NSDictionary) {

        }

        override func onContactsUpdated(_ data: NSDictionary) {

        }

        override func onClientSendMessage(_ data: NSDictionary) {

        }

        override func onOperatorSendMessage(_ data: NSDictionary) {
            super.onOperatorSendMessage(data)
        }

        override func onClientMakeSubscribe(_ data: NSDictionary) {

        }

        override func onEvent(_ name: String, _ data: NSDictionary) {

        }

        override func getContactsCallback(_ data: NSDictionary) {

        }
}
