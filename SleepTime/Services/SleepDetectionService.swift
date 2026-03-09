import Foundation
import SwiftData

struct SleepDetectionService {
    static let defaultMinSleepDuration: TimeInterval = 4 * 3600 // 4 hours
    static let defaultMaxSleepDuration: TimeInterval = 12 * 3600 // 12 hours
    static let defaultSleepWindowStart = 20 // 8 PM
    static let defaultSleepWindowEnd = 10   // 10 AM

    private static let duplicateTolerance: TimeInterval = 30 * 60
    private static let futureTimestampGrace: TimeInterval = 5 * 60

    /// Analyzes activity timestamps to detect sleep periods.
    /// Returns new SleepRecord instances for any detected sleep that isn't already recorded.
    static func detectSleep(
        timestamps: [ActivityTimestamp],
        existingRecords: [SleepRecord],
        minDuration: TimeInterval = defaultMinSleepDuration,
        maxDuration: TimeInterval = defaultMaxSleepDuration,
        windowStart: Int = defaultSleepWindowStart,
        windowEnd: Int = defaultSleepWindowEnd
    ) -> [SleepRecord] {
        guard minDuration > 0 else { return [] }
        guard maxDuration >= minDuration else { return [] }

        let normalizedWindowStart = normalizedHour(windowStart)
        let normalizedWindowEnd = normalizedHour(windowEnd)

        let now = Date.now
        let validTimestamps = timestamps.filter { $0.date <= now.addingTimeInterval(futureTimestampGrace) }
        guard validTimestamps.count >= 2 else { return [] }

        let sorted = validTimestamps.sorted { $0.date < $1.date }
        var detected: [SleepRecord] = []

        for i in 0..<(sorted.count - 1) {
            let gapStart = sorted[i].date
            let gapEnd = sorted[i + 1].date
            guard gapEnd > gapStart else { continue }
            let gap = gapEnd.timeIntervalSince(gapStart)
            guard gap >= minDuration, gap <= maxDuration else { continue }

            guard isInSleepWindow(date: gapStart, windowStart: normalizedWindowStart, windowEnd: normalizedWindowEnd) else { continue }
            let midpoint = gapStart.addingTimeInterval(gap / 2)
            guard isInSleepWindow(date: midpoint, windowStart: normalizedWindowStart, windowEnd: normalizedWindowEnd) else { continue }

            let alreadyRecorded = existingRecords.contains { existing in
                isLikelyDuplicate(
                    existing: existing,
                    candidateStart: gapStart,
                    candidateEnd: gapEnd
                )
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
        maxDuration: TimeInterval = defaultMaxSleepDuration,
        windowStart: Int = defaultSleepWindowStart,
        windowEnd: Int = defaultSleepWindowEnd
    ) -> [SleepRecord] {
        var allTimestamps = timestamps
        allTimestamps.append(ActivityTimestamp(date: .now, source: .foreground))
        return detectSleep(
            timestamps: allTimestamps,
            existingRecords: existingRecords,
            minDuration: minDuration,
            maxDuration: maxDuration,
            windowStart: windowStart,
            windowEnd: windowEnd
        )
    }

    private static func isLikelyDuplicate(existing: SleepRecord, candidateStart: Date, candidateEnd: Date) -> Bool {
        let existingStart = existing.sleepStart
        let existingEnd = existing.sleepEnd

        guard existingEnd > existingStart else { return false }

        let startDelta = abs(existingStart.timeIntervalSince(candidateStart))
        let endDelta = abs(existingEnd.timeIntervalSince(candidateEnd))
        if startDelta <= duplicateTolerance && endDelta <= duplicateTolerance {
            return true
        }

        let overlapStart = max(existingStart, candidateStart)
        let overlapEnd = min(existingEnd, candidateEnd)
        let overlap: TimeInterval = overlapEnd.timeIntervalSince(overlapStart)
        guard overlap > 0 else { return false }

        let existingDuration: TimeInterval = existingEnd.timeIntervalSince(existingStart)
        let candidateDuration: TimeInterval = candidateEnd.timeIntervalSince(candidateStart)
        let shorterDuration: TimeInterval = min(existingDuration, candidateDuration)
        guard shorterDuration > 0 else { return false }

        return overlap / shorterDuration >= 0.7
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

    private static func normalizedHour(_ hour: Int) -> Int {
        ((hour % 24) + 24) % 24
    }
}
