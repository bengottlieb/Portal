//
//  ContentView.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import SwiftUI
import Portal

extension PortalMessage.Kind {
	public static let pong = PortalMessage.Kind(rawValue: "_pong")
}

struct ContentView: View {
	@ObservedObject var portal = PortalToWatch.instance
	var body: some View {
		HStack() {
			Button("Ping") {
				PortalToWatch.instance.send(PortalMessage(.ping))
			}
			Button("Pong") {
				PortalToWatch.instance.send(PortalMessage(.pong))
			}
			
			Button("Send Image") {
				let file = Bundle.main.url(forResource: "apple", withExtension: "jpeg")!
				PortalToWatch.instance.send(file)
			}
		}
		if let kind = portal.mostRecentMessage?.kind.rawValue {
			Text(kind)
				.padding()
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
