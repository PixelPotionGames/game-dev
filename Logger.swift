import Foundation

enum LogLevel: String {
    case general
    case error
}

class Logger {
    static func log(_ message: String, level: LogLevel = .general) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .long)
        let formattedMessage = "[\(timestamp)] [\(level.rawValue.uppercased())]: \(message)"
        print(formattedMessage)
    }
}
