import Foundation
import Combine
import HealthKit

@MainActor
final class HealthService: ObservableObject {
    @Published private(set) var steps: Int? = nil
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdated: Date? = nil

    @Published private(set) var message =
        "Connect Apple Health to view today's recorded steps."

    private let healthStore = HKHealthStore()
    private let defaults: UserDefaults
    private let disabled: Bool

    private let requestKey = "healthAccessRequested"

    init(
        disabled: Bool = false,
        defaults: UserDefaults = .standard
    ) {
        self.disabled = disabled
        self.defaults = defaults
    }

    var isAvailable: Bool {
        !disabled && HKHealthStore.isHealthDataAvailable()
    }

    // This records that we requested access.
    // It does not prove that the user granted read permission.
    var hasRequestedAccess: Bool {
        !disabled && defaults.bool(forKey: requestKey)
    }

    // Called when the user taps Connect Apple Health.
    func connect() async {
        guard !isLoading else {
            return
        }

        guard isAvailable else {
            message = """
            Apple Health is unavailable here. \
            Tasks and study goals still work.
            """
            return
        }

        guard let stepType = HKQuantityType.quantityType(
            forIdentifier: .stepCount
        ) else {
            message = "Step tracking is unavailable on this device."
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {
            // Read steps only. We do not write health data.
            try await healthStore.requestAuthorization(
                toShare: [],
                read: [stepType]
            )

            defaults.set(true, forKey: requestKey)

            await queryTodaySteps()
        } catch {
            steps = nil
            lastUpdated = nil

            message = """
            Apple Health access could not be requested. \
            Try again and check your device's Health settings.
            """
        }
    }

    // Refresh without repeatedly opening the permission screen.
    func refreshIfRequested() async {
        guard hasRequestedAccess,
              isAvailable,
              !isLoading else {
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        await queryTodaySteps()
    }

    private func queryTodaySteps() async {
        guard let stepType = HKQuantityType.quantityType(
            forIdentifier: .stepCount
        ) else {
            steps = nil
            lastUpdated = nil
            message = "Step tracking is unavailable on this device."
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        do {
            let total: Double? =
                try await withCheckedThrowingContinuation {
                    (continuation: CheckedContinuation<Double?, Error>) in

                    let query = HKStatisticsQuery(
                        quantityType: stepType,
                        quantitySamplePredicate: predicate,
                        options: .cumulativeSum
                    ) { _, result, error in

                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }

                        let count = result?
                            .sumQuantity()?
                            .doubleValue(for: .count())

                        continuation.resume(returning: count)
                    }

                    healthStore.execute(query)
                }

            if let total = total {
                steps = max(0, Int(total))
                lastUpdated = now

                message = """
                Today's recorded steps from Apple Health. \
                Refresh to check for updates.
                """
            } else {
                steps = nil
                lastUpdated = nil

                message = """
                No step data is available for today. \
                There may be no recorded steps, or read access \
                may be off. Check Apple Health and its sharing settings.
                """
            }
        } catch {
            steps = nil
            lastUpdated = nil

            message = """
            Step data could not be read. Unlock your device, \
            check Apple Health access, and try refreshing.
            """
        }
    }
}