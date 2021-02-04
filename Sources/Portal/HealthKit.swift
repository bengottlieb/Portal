//
//  HealthKit.swift
//  
//
//  Created by Ben Gottlieb on 2/2/21.
//

import Foundation
import HealthKit

public extension HKStatistics {
	var heartRate: Int? {
		let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
		guard let value = mostRecentQuantity()?.doubleValue(for: heartRateUnit) else { return nil }
		let roundedValue = Double( round( 1 * value ) / 1 )
		return Int(roundedValue)
	}
}

public extension HKSample {
	var heartRate: Int? {
	//	guard self is HKQuantityTypeIdentifierHeartRate else { return nil }

		guard let quantitySample = self as? HKQuantitySample else { return nil }
		let units = HKUnit.minute().reciprocal()

		if !quantitySample.quantity.is(compatibleWith: units) { return nil }
		let value = quantitySample.quantity.doubleValue(for: units)
		return Int(value)
	}

	var calories: Double? {
		guard let quantitySample = self as? HKQuantitySample else { return nil }
		let units = HKUnit.largeCalorie()

		if !quantitySample.quantity.is(compatibleWith: units) { return nil }
		let value = quantitySample.quantity.doubleValue(for: units)
		return value
	}
}

