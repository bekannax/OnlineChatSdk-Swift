import Foundation

class ChatConfig {

    nonisolated(unsafe) private static var instance: ChatConfig?

    private struct ConfigKeys {
        
        @available(*, deprecated)
        static let configKeyApiTokenOld = "onlineChatSdkConfig_apiToken"
        
        static let configKeyLastDateTimeNewMessage = "onlineChatSdkConfig_lastDateTimeNewMessage"
        static let configKeyClientId = "onlineChatSdkConfig_clientId"
        static let configKeySiteId = "onlineChatSdkConfig_siteId"
        static let configKeyOrgId = "onlineChatSdkConfig_orgId"
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
    
    public static func setSiteId(_ siteId: String) {
        getInstance().setConfig(ConfigKeys.configKeySiteId, siteId)
    }

    public static func getSiteId() -> String {
        getInstance().getConfigString(ConfigKeys.configKeySiteId)
    }
    
    public static func setOrgId(_ orgId: String) {
        getInstance().setConfig(ConfigKeys.configKeyOrgId, orgId)
    }

    public static func getOrgId() -> String {
        getInstance().getConfigString(ConfigKeys.configKeyOrgId)
    }

    @available(*, deprecated)
    public static func setApiToken(_ apiToken: String) {
        getInstance().setConfig(ConfigKeys.configKeyApiTokenOld, apiToken)
    }

    @available(*, deprecated)
    public static func getApiToken() -> String {
        getInstance().getConfigString(ConfigKeys.configKeyApiTokenOld)
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
