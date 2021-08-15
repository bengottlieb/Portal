//
//  SwiftUIView.swift
//  
//
//  Created by Ben Gottlieb on 8/15/21.
//

import SwiftUI

@available(iOS 14.0, watchOS 7.0, *)
public struct PortalConnectionIndicator: View {
	@ObservedObject var portal = DevicePortal.instance

	public init() { }
	public var body: some View {
		Circle()
			.fill(portal.isReachable ? Color.green : Color.red)
			.frame(width: 10, height: 10)
			.frame(width: 50, height: 50)
			.background(Color.white.opacity(0.1))
			.clipShape(Circle())
			.onTapGesture {
				PortalConsoleLayer.showConsole.toggle()
			}
			.zIndex(101)
	}
}

@available(iOS 14.0, watchOS 7.0, *)
public struct FullScreenConnectionIndicator: View {
	public init() { }
	public var body: some View {
		VStack() {
			#if os(iOS)
				HStack() {
					PortalConnectionIndicator()
						.padding(20)
						.opacity(0.9)
					Spacer()
				}
				Spacer()
			#else
				Spacer()
				HStack() {
					Spacer()
					PortalConnectionIndicator()
						.padding(20)
						.opacity(0.9)
				}
			#endif
		}
	}
}

@available(iOS 14.0, watchOS 7.0, *)
struct PortalConnectionIndicator_Previews: PreviewProvider {
	static var previews: some View {
		PortalConnectionIndicator()
	}
}
