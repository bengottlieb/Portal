//
//  PortalToWatch.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

#if os(iOS)
#if canImport(Combine)

import Foundation
import SwiftUI
import WatchConnectivity
import Combine

@available(iOS 13.0, watchOS 7.0, *)
public class PortalToWatch: DevicePortal {
	public override var isWatchAppInstalled: Bool { session?.isWatchAppInstalled ?? false }
	public override var isPaired: Bool { session?.isPaired ?? false }

	public static func setup(messageHandler: PortalMessageHandler) {
		DevicePortal.instance = PortalToWatch(messageHandler: messageHandler)
	}
}
#endif
#endif
