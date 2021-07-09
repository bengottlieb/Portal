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
	@Binding var collapsed: Bool
	
	public var body: some View {
		HStack() {
			Button("Ping") { DevicePortal.instance.checkLatency() }
				.padding(5)
				.padding(.horizontal, 4)
				.background(Capsule().fill(Color.white.opacity(portal.isReachable ? 1 : 0.5)))
				.padding(.horizontal, 3)

			Button("Incoming") {
				portal.logIncomingMessages.toggle()
			}
			.padding(5)
			.padding(.horizontal, 4)
			.background(Capsule().fill(Color.white.opacity(portal.logIncomingMessages ? 1 : 0.5)))
			.padding(.horizontal, 3)

			Button("Outgoing") {
				portal.logOutgoingMessages.toggle()
			}
			.padding(5)
			.padding(.horizontal, 4)
			.background(Capsule().fill(Color.white.opacity(portal.logOutgoingMessages ? 1 : 0.5)))
			.padding(.horizontal, 3)
		Spacer()
			
			if let latency = portal.lastReportedLatency {
				Text("\(latency)s")
					.font(.system(size: 10))
					.foregroundColor(.white)
			}
			
			Button(action: toggleCollapsed) {
				Image(systemName: "arrowtriangle.backward.fill")
					.rotationEffect(.degrees(collapsed ? 0 : 90))
					.animation(.default)
					.foregroundColor(.white)
					.padding(5)
			}
		}
		.frame(height: 30)
		.font(.system(size: 12))
		.foregroundColor(.black)
		.background(Color.black)
	}
	
	func toggleCollapsed() {
		withAnimation(.easeIn(duration: 0.1)) {
			collapsed.toggle()
		}
	}
}

@available(iOS 14.0, watchOS 7.0, *)
struct PortalControlsBar_Previews: PreviewProvider {
	static var previews: some View {
		PortalControlsBar(collapsed: .constant(false))
	}
}
