//
//  HealthKitManager.swift
//  StepMap
//
//  Created by Oliver Hnát on 27.11.2024.
//

import Foundation
import HealthKit

/// Describes how the step length was determined
enum StepLengthSource: String {
    case walkingWorkouts = "Recent walking workouts"
    case outdoorSpeedFiltered = "Outdoor walking pace"
    case recentSamples = "Recent activity"
    case overallAverage = "Overall average"
    case manual = "Manual"
}

/// Describes how the walking speed was determined
enum WalkingSpeedSource: String {
    case walkingWorkouts = "Recent walking workouts"
    case outdoorSpeedFiltered = "Outdoor walking pace"
    case recentSamples = "Recent activity"
    case overallAverage = "Overall average"
    case manual = "Manual"
}

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()
    let allTypes: Set<HKObjectType> = [
        HKQuantityType(.walkingSpeed),
        HKQuantityType(.walkingStepLength),
        HKQuantityType(.stepCount),
        HKObjectType.workoutType()
    ]
    
    // Outdoor walking speed range (m/s): 4-6 km/h = 1.1-1.7 m/s
    private let minOutdoorWalkingSpeed: Double = 1.1
    private let maxOutdoorWalkingSpeed: Double = 1.7
    private let recentDays: Int = 30

    var stepLength: Double?
    var walkingSpeed: Double?
    var stepLengthSource: StepLengthSource?
    var walkingSpeedSource: WalkingSpeedSource?
    
    var stepCount: Int?

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

    /// Main method that tries cascading approaches to get the best step length
    func getStepLength() async -> Double? {
        if stepLength != nil {
            return stepLength
        }
        
        // Try cascading approaches
        if let length = await getStepLengthFromWalkingWorkouts() {
            stepLength = length
            stepLengthSource = .walkingWorkouts
            return stepLength
        }
        
        if let length = await getStepLengthAtOutdoorWalkingSpeed() {
            stepLength = length
            stepLengthSource = .outdoorSpeedFiltered
            return stepLength
        }
        
        if let length = await getRecentStepLength() {
            stepLength = length
            stepLengthSource = .recentSamples
            return stepLength
        }
        
        if let length = await getOverallAverageStepLength() {
            stepLength = length
            stepLengthSource = .overallAverage
            return stepLength
        }
        
        return nil
    }
    
    /// Gets step length from walking workout periods
    private func getStepLengthFromWalkingWorkouts() async -> Double? {
        let workoutType = HKObjectType.workoutType()
        let stepLengthType = HKQuantityType(.walkingStepLength)
        
        // Get walking workouts from the last 30 days
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -recentDays, to: Date()) else {
            return nil
        }
        
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, datePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        do {
            let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: workoutType,
                    predicate: compoundPredicate,
                    limit: 20,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
                healthStore.execute(query)
            }
            
            guard !workouts.isEmpty else { return nil }
            
            // Get step length samples during workout periods
            var stepLengths: [Double] = []
            
            for workout in workouts {
                let workoutDatePredicate = HKQuery.predicateForSamples(
                    withStart: workout.startDate,
                    end: workout.endDate,
                    options: .strictStartDate
                )
                
                let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                    let query = HKSampleQuery(
                        sampleType: stepLengthType,
                        predicate: workoutDatePredicate,
                        limit: HKObjectQueryNoLimit,
                        sortDescriptors: nil
                    ) { _, samples, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                    }
                    healthStore.execute(query)
                }
                
                for sample in samples {
                    let length = sample.quantity.doubleValue(for: HKUnit.meter())
                    stepLengths.append(length)
                }
            }
            
            guard !stepLengths.isEmpty else { return nil }
            
            let average = stepLengths.reduce(0, +) / Double(stepLengths.count)
            return average
            
        } catch {
            print("Error getting step length from workouts: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets step length correlated with outdoor walking speed (1.1-1.7 m/s)
    private func getStepLengthAtOutdoorWalkingSpeed() async -> Double? {
        let stepLengthType = HKQuantityType(.walkingStepLength)
        let walkingSpeedType = HKQuantityType(.walkingSpeed)
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -recentDays, to: Date()) else {
            return nil
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        do {
            // Get speed samples in the outdoor walking range
            let speedSamples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: walkingSpeedType,
                    predicate: datePredicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
                healthStore.execute(query)
            }
            
            // Filter to outdoor walking speed range
            let outdoorSpeedSamples = speedSamples.filter { sample in
                let speed = sample.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second()))
                return speed >= minOutdoorWalkingSpeed && speed <= maxOutdoorWalkingSpeed
            }
            
            guard !outdoorSpeedSamples.isEmpty else { return nil }
            
            // Get step length samples that overlap with these time periods
            var stepLengths: [Double] = []
            
            for speedSample in outdoorSpeedSamples {
                // Allow a small time window for correlation (samples might not be exactly aligned)
                let startTime = speedSample.startDate.addingTimeInterval(-30)
                let endTime = speedSample.endDate.addingTimeInterval(30)
                
                let timePredicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: .strictStartDate)
                
                let stepSamples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                    let query = HKSampleQuery(
                        sampleType: stepLengthType,
                        predicate: timePredicate,
                        limit: 10,
                        sortDescriptors: nil
                    ) { _, samples, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                    }
                    healthStore.execute(query)
                }
                
                for sample in stepSamples {
                    let length = sample.quantity.doubleValue(for: HKUnit.meter())
                    stepLengths.append(length)
                }
            }
            
            guard !stepLengths.isEmpty else { return nil }
            
            let average = stepLengths.reduce(0, +) / Double(stepLengths.count)
            return average
            
        } catch {
            print("Error getting step length at outdoor walking speed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets average step length from the last 30 days
    private func getRecentStepLength() async -> Double? {
        let stepLengthType = HKQuantityType(.walkingStepLength)
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -recentDays, to: Date()) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: stepLengthType, predicate: predicate),
            options: .discreteAverage
        )
        
        do {
            let results = try await query.result(for: healthStore)
            return results?.averageQuantity()?.doubleValue(for: HKUnit.meter())
        } catch {
            print("Error getting recent step length: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets overall average step length (fallback)
    private func getOverallAverageStepLength() async -> Double? {
        let stepLengthType = HKQuantityType(.walkingStepLength)

        let query = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: stepLengthType),
            options: .discreteAverage)
        
        do {
            let results = try await query.result(for: healthStore)
            return results?.averageQuantity()?.doubleValue(for: HKUnit.meter())
        } catch {
            print("Error getting overall average step length: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Walking Speed Methods
    
    /// Main method that tries cascading approaches to get the best walking speed
    func getWalkingSpeed() async -> Double? {
        if walkingSpeed != nil {
            return walkingSpeed
        }
        
        // Try cascading approaches
        if let speed = await getWalkingSpeedFromWalkingWorkouts() {
            walkingSpeed = speed
            walkingSpeedSource = .walkingWorkouts
            return walkingSpeed
        }
        
        if let speed = await getWalkingSpeedAtOutdoorPace() {
            walkingSpeed = speed
            walkingSpeedSource = .outdoorSpeedFiltered
            return walkingSpeed
        }
        
        if let speed = await getRecentWalkingSpeed() {
            walkingSpeed = speed
            walkingSpeedSource = .recentSamples
            return walkingSpeed
        }
        
        if let speed = await getOverallAverageWalkingSpeed() {
            walkingSpeed = speed
            walkingSpeedSource = .overallAverage
            return walkingSpeed
        }
        
        return nil
    }
    
    /// Gets walking speed from walking workout periods
    private func getWalkingSpeedFromWalkingWorkouts() async -> Double? {
        let workoutType = HKObjectType.workoutType()
        let walkingSpeedType = HKQuantityType(.walkingSpeed)
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -recentDays, to: Date()) else {
            return nil
        }
        
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, datePredicate])
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        do {
            let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: workoutType,
                    predicate: compoundPredicate,
                    limit: 20,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples as? [HKWorkout] ?? [])
                }
                healthStore.execute(query)
            }
            
            guard !workouts.isEmpty else { return nil }
            
            var speeds: [Double] = []
            
            for workout in workouts {
                let workoutDatePredicate = HKQuery.predicateForSamples(
                    withStart: workout.startDate,
                    end: workout.endDate,
                    options: .strictStartDate
                )
                
                let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                    let query = HKSampleQuery(
                        sampleType: walkingSpeedType,
                        predicate: workoutDatePredicate,
                        limit: HKObjectQueryNoLimit,
                        sortDescriptors: nil
                    ) { _, samples, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                    }
                    healthStore.execute(query)
                }
                
                for sample in samples {
                    let speed = sample.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second()))
                    speeds.append(speed)
                }
            }
            
            guard !speeds.isEmpty else { return nil }
            return speeds.reduce(0, +) / Double(speeds.count)
            
        } catch {
            print("Error getting walking speed from workouts: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets walking speed filtered to outdoor walking pace (1.1-1.7 m/s)
    private func getWalkingSpeedAtOutdoorPace() async -> Double? {
        let walkingSpeedType = HKQuantityType(.walkingSpeed)
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -recentDays, to: Date()) else {
            return nil
        }
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        do {
            let speedSamples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: walkingSpeedType,
                    predicate: datePredicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                }
                healthStore.execute(query)
            }
            
            let outdoorSpeedSamples = speedSamples.compactMap { sample -> Double? in
                let speed = sample.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second()))
                return (speed >= minOutdoorWalkingSpeed && speed <= maxOutdoorWalkingSpeed) ? speed : nil
            }
            
            guard !outdoorSpeedSamples.isEmpty else { return nil }
            return outdoorSpeedSamples.reduce(0, +) / Double(outdoorSpeedSamples.count)
            
        } catch {
            print("Error getting walking speed at outdoor pace: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets average walking speed from the last 30 days
    private func getRecentWalkingSpeed() async -> Double? {
        let walkingSpeedType = HKQuantityType(.walkingSpeed)
        
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -recentDays, to: Date()) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: walkingSpeedType, predicate: predicate),
            options: .discreteAverage
        )
        
        do {
            let results = try await query.result(for: healthStore)
            return results?.averageQuantity()?.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second()))
        } catch {
            print("Error getting recent walking speed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets overall average walking speed (fallback)
    private func getOverallAverageWalkingSpeed() async -> Double? {
        let walkingSpeedType = HKQuantityType(.walkingSpeed)
        
        let query = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate.quantitySample(type: walkingSpeedType),
            options: .discreteAverage)
        
        do {
            let results = try await query.result(for: healthStore)
            return results?.averageQuantity()?.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second()))
        } catch {
            print("Error getting overall average walking speed: \(error.localizedDescription)")
            return nil
        }
    }
}
