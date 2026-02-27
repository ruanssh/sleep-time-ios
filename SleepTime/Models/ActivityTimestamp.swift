import Foundation
import SwiftData

@Model
final class ActivityTimestamp {
    var date: Date
    var source: ActivitySource

    init(date: Date = .now, source: ActivitySource = .foreground) {
        self.date = date
        self.source = source
    }
}

enum ActivitySource: String, Codable {
    case foreground
    case backgroundRefresh
}
