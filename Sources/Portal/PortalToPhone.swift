//
//  PortalToPhone.swift
//  Portal_Watch
//
//  Created by Ben Gottlieb on 10/17/20.
//

#if os(watchOS)
#if canImport(Combine)

import Foundation
import SwiftUI
import WatchKit
import WatchConnectivity
import Combine

@available(iOS 13.0, watchOS 7.0, *)
public class PortalToPhone: DevicePortal {
	public static func setup(messageHandler: PortalMessageHandler) {
		DevicePortal.instance = PortalToPhone(messageHandler: messageHandler)
	}

	override public var heartRate: Int? { didSet {
		if let rate = heartRate {
			let message = PortalMessage.init(heartRate: rate, date: Date())
			send(message)
		}
	}}
}

#endif
#endif
