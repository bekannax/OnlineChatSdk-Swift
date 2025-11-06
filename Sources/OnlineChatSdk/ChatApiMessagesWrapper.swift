import Foundation

class ChatApiMessagesWrapper {

    private var result: Dictionary<String, Any>?
    private var dataArray: Array<Dictionary<String, Any>>?
    private var data: Dictionary<String, Any>?
    private var messages: Array<Dictionary<String, Any>>?

    init(_ response: NSDictionary) {
        self.result = response as? Dictionary<String, Any>
        self.dataArray = []
        self.data = [:]
        self.messages = []
        if response["result"] == nil {
            return
        }
        self.dataArray = response["result"] as? Array<Dictionary<String, Any>>
        if self.dataArray == nil || self.dataArray?.count == 0 {
            return
        }
        self.data = dataArray![0]
        if self.data == nil || self.data!["messages"] == nil {
            self.data = [:]
            return
        }
        self.messages = self.data!["messages"] as? Array<Dictionary<String, Any>>
        if self.messages == nil {
            self.messages = []
        }
    }

    public func getMessages() -> NSArray {
        self.messages! as NSArray
    }

    public func setMessages(_ messages: NSArray) {
        self.messages = messages as? Array<Dictionary<String, Any>>
    }

    public func getResult() -> NSDictionary {
        self.data!["messages"] = self.messages
        if self.dataArray?.count == 0 {
            self.dataArray = [self.data!]
        } else {
            self.dataArray![0] = self.data!
        }
        self.result?["result"] = self.dataArray
        return self.result! as NSDictionary
    }
}