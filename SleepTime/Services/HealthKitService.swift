import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    private var sleepType: HKCategoryType {
        HKCategoryType(.sleepAnalysis)
    }

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [sleepType], read: [sleepType])
    }

    func saveSleepRecord(_ record: SleepRecord) async throws {
        guard isAvailable else { return }

        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: record.sleepStart,
            end: record.sleepEnd
        )

        try await store.save(sample)
    }

    func authorizationStatus() -> HKAuthorizationStatus {
        store.authorizationStatus(for: sleepType)
    }
}
