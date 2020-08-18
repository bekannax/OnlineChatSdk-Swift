import Foundation

class ChatDateFormatter : DateFormatter {

    override init() {
        super.init()
        self.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        self.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'"
        self.locale = Locale(identifier: "en")
        self.timeZone = TimeZone(secondsFromGMT: 10800)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func getCurrent() -> String {
        self.string(from: NSDate() as Date)
    }
}
