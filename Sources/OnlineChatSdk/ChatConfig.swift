import Foundation

class ChatConfig {

    nonisolated(unsafe) private static var instance: ChatConfig?

    private struct ConfigKeys {
        static let configKeyApiToken = "onlineChatSdkConfig_apiToken"
        static let configKeyClientId = "onlineChatSdkConfig_clientId"
        static let configKeyLastDateTimeNewMessage = "onlineChatSdkConfig_lastDateTimeNewMessage"
    }

    private let config: UserDefaults

    init() {
        self.config = UserDefaults.standard
    }

    private static func getInstance() -> ChatConfig {
        if instance == nil {
            instance = ChatConfig()
        }
        return instance!
    }

    public static func setLastDateTimeNewMessage(_ dateTime: String) {
        getInstance().setConfig(ConfigKeys.configKeyLastDateTimeNewMessage, dateTime)
    }

    public static func getLastDateTimeNewMessage() -> String {
        getInstance().getConfigString(ConfigKeys.configKeyLastDateTimeNewMessage)
    }

    public static func setClientId(_ clientId: String) {
        getInstance().setConfig(ConfigKeys.configKeyClientId, clientId)
    }

    public static func getClientId() -> String {
        getInstance().getConfigString(ConfigKeys.configKeyClientId)
    }

    public static func setApiToken(_ apiToken: String) {
        getInstance().setConfig(ConfigKeys.configKeyApiToken, apiToken)
    }

    public static func getApiToken() -> String {
        getInstance().getConfigString(ConfigKeys.configKeyApiToken)
    }

    private func setConfig(_ key: String, _ value: String) {
        self.config.set(value, forKey: key)
    }

    private func setConfig(_ key: String, _ value: Int) {
        self.config.set(value, forKey: key)
    }

    private func getConfigString(_ key: String) -> String {
        self.config.value(forKey: key) != nil ? self.config.value(forKey: key) as! String : ""
    }
}
