//
// Created by Andrew Blinov on 20.10.2026.
//

import Foundation

public class ChatApiGetClientUnreadMessageCountResponseModel {
    public var error: ChatApiResponseErrorModel?
    public var result: Int

    public init(error: ChatApiResponseErrorModel) {
        self.error = error
        self.result = 0
    }

    public init(result: Int) {
        self.error = nil
        self.result = result
    }
}
