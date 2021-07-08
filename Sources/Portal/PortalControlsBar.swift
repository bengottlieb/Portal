//
//  PortalControlsBar.swift
//  
//
//  Created by Ben Gottlieb on 7/7/21.
//

import SwiftUI

@available(iOS 14.0, watchOS 7.0, *)
public struct PortalControlsBar: View {
	@ObservedObject var portal = DevicePortal.instance
	public init() { }
	
	public var body: some View {
		HStack() {
			Button("Ping") { DevicePortal.instance.checkLatency() }
				.padding(5)
				.padding(.horizontal, 4)
				.background(Capsule().fill(Color.white.opacity(portal.isReachable ? 1 : 0.5)))
			
			Button("Incoming") {
				portal.logIncomingMessages.toggle()
			}
			.padding(5)
			.padding(.horizontal, 4)
			.background(Capsule().fill(Color.white.opacity(portal.logIncomingMessages ? 1 : 0.5)))

			Button("Outgoing") {
				portal.logOutgoingMessages.toggle()
			}
			.padding(5)
			.padding(.horizontal, 4)
			.background(Capsule().fill(Color.white.opacity(portal.logOutgoingMessages ? 1 : 0.5)))
			Spacer()
			
			if let latency = portal.lastReportedLatency {
				Text("\(latency)s")
					.font(.system(size: 10))
					.foregroundColor(.white)
			}
		}
		.frame(height: 30)
		.font(.system(size: 12))
		.foregroundColor(.black)
		.background(Color.black)
	}
}

@available(iOS 14.0, watchOS 7.0, *)
struct PortalControlsBar_Previews: PreviewProvider {
	static var previews: some View {
		PortalControlsBar()
	}
}
