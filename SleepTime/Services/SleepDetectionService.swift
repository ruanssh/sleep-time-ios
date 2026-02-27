import Foundation
import SwiftData

struct SleepDetectionService {
    static let defaultMinSleepDuration: TimeInterval = 4 * 3600 // 4 hours
    static let defaultSleepWindowStart = 20 // 8 PM
    static let defaultSleepWindowEnd = 10   // 10 AM

    /// Analyzes activity timestamps to detect sleep periods.
    /// Returns new SleepRecord instances for any detected sleep that isn't already recorded.
    static func detectSleep(
        timestamps: [ActivityTimestamp],
        existingRecords: [SleepRecord],
        minDuration: TimeInterval = defaultMinSleepDuration,
        windowStart: Int = defaultSleepWindowStart,
        windowEnd: Int = defaultSleepWindowEnd
    ) -> [SleepRecord] {
        guard timestamps.count >= 2 else { return [] }

        let sorted = timestamps.sorted { $0.date < $1.date }
        var detected: [SleepRecord] = []

        for i in 0..<(sorted.count - 1) {
            let gapStart = sorted[i].date
            let gapEnd = sorted[i + 1].date
            let gap = gapEnd.timeIntervalSince(gapStart)

            guard gap >= minDuration else { continue }
            guard isInSleepWindow(date: gapStart, windowStart: windowStart, windowEnd: windowEnd) else { continue }

            let alreadyRecorded = existingRecords.contains { existing in
                abs(existing.sleepStart.timeIntervalSince(gapStart)) < 1800 &&
                abs(existing.sleepEnd.timeIntervalSince(gapEnd)) < 1800
            }

            if !alreadyRecorded {
                detected.append(SleepRecord(sleepStart: gapStart, sleepEnd: gapEnd))
            }
        }

        return detected
    }

    /// Also check current time as a potential gap end (user just opened the app).
    static func detectSleepIncludingNow(
        timestamps: [ActivityTimestamp],
        existingRecords: [SleepRecord],
        minDuration: TimeInterval = defaultMinSleepDuration,
        windowStart: Int = defaultSleepWindowStart,
        windowEnd: Int = defaultSleepWindowEnd
    ) -> [SleepRecord] {
        var allTimestamps = timestamps
        allTimestamps.append(ActivityTimestamp(date: .now, source: .foreground))
        return detectSleep(
            timestamps: allTimestamps,
            existingRecords: existingRecords,
            minDuration: minDuration,
            windowStart: windowStart,
            windowEnd: windowEnd
        )
    }

    private static func isInSleepWindow(date: Date, windowStart: Int, windowEnd: Int) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        if windowStart > windowEnd {
            // Wraps midnight: e.g. 20-10 means 20,21,22,23,0,1,...,9
            return hour >= windowStart || hour < windowEnd
        } else {
            return hour >= windowStart && hour < windowEnd
        }
    }
}
