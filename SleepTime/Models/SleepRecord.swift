import Foundation
import SwiftData

@Model
final class SleepRecord {
    var sleepStart: Date
    var sleepEnd: Date
    var duration: TimeInterval
    var syncedToHealthKit: Bool

    var quality: SleepQuality {
        let hours = duration / 3600
        if hours < 6 { return .poor }
        if hours < 8 { return .fair }
        return .good
    }

    init(sleepStart: Date, sleepEnd: Date) {
        self.sleepStart = sleepStart
        self.sleepEnd = sleepEnd
        self.duration = sleepEnd.timeIntervalSince(sleepStart)
        self.syncedToHealthKit = false
    }
}

enum SleepQuality: String, Codable {
    case poor
    case fair
    case good

    var label: String {
        switch self {
        case .poor: "Ruim"
        case .fair: "Regular"
        case .good: "Bom"
        }
    }

    var color: String {
        switch self {
        case .poor: "red"
        case .fair: "orange"
        case .good: "green"
        }
    }

    var icon: String {
        switch self {
        case .poor: "moon.zzz"
        case .fair: "moon"
        case .good: "moon.stars"
        }
    }
}
