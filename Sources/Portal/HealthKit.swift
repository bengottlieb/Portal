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
		guard let quantity = averageQuantity() else { return nil }

		let units = HKUnit.minute().reciprocal()
		let value = quantity.doubleValue(for: units)
		return Int(value)
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

