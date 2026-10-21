//
// Created by Andrew Blinov on 20.10.2026.
//

import Foundation

public class ChatApiResponseModel {
    var error: ChatApiResponseErrorModel?
    var result: String

    init(error: ChatApiResponseErrorModel) {
        self.error = error
        self.result = ""
    }

    init(result: String) {
        self.error = nil
        self.result = result
    }
}
