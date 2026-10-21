//
// Created by Andrew Blinov on 20.10.2026.
//

import Foundation

public class ChatApiResponseErrorModel {
    public var code: Int
    public var descr: String

    init(code: Int, descr: String) {
        self.code = code
        self.descr = descr
    }
}
