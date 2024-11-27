//
//  HealthKitManager.swift
//  StepMap
//
//  Created by Oliver Hnát on 27.11.2024.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    let allTypes: Set = [
        HKQuantityType(.walkingSpeed),
        HKQuantityType(.walkingStepLength),
    ]

    var stepLength: Double?

    func requestAccess() async {
        do {
            if HKHealthStore.isHealthDataAvailable() {
                try await healthStore.requestAuthorization(toShare: Set(), read: allTypes)
            }
        } catch {
            fatalError(
                "Something went wrong while requesting healthKit permissions: \(error.localizedDescription)"
            )
        }
    }

    func getStepLength() async -> Double? {
        if stepLength != nil {
            return stepLength
        }
        let stepLengthType = HKQuantityType(.walkingStepLength)

        let query = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: stepLengthType),
            options: .discreteAverage)
        // maybe make an average of all the ones gotten in the last week?
        do {
            let results = try await query.result(for: healthStore)
            stepLength = results?.averageQuantity()?.doubleValue(for: HKUnit.meter())
            return stepLength
        } catch {
            fatalError(
                "Something went wrong while getting step length from healthKit: \(error.localizedDescription)"
            )
        }
    }

}
