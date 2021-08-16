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

	@State var scale: CGFloat = 1.0
	public init() { }
	public var body: some View {
		Circle()
			.fill(portal.isReachable ? Color.green : Color.red)
			.frame(width: 10, height: 10)
			.frame(width: 50, height: 50)
			.background(Color.white.opacity(0.1))
			.clipShape(Circle())
			.scaleEffect(scale)
			.onTapGesture {
				PortalConsoleLayer.showConsole.toggle()
			}
			.zIndex(101)
			.onReceive(NotificationCenter.default.publisher(for: DevicePortal.Notifications.pingReceived)) { _ in
				let duration = 0.25
				withAnimation(.linear(duration: duration)) { scale = 2.0 }
				
				DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
					withAnimation(.linear(duration: duration)) { scale = 1.0 }
				}
			}
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
