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
	@EnvironmentObject var router: ImageRouter
	
	var body: some View {
		HStack() {
			Button("Ping") {
				PortalToWatch.instance.send("message ping")
			}
			Button("Pong") {
				PortalToWatch.instance.send("pong message")
			}
			
			if let image = router.image {
				image
			}
			Button("Send Image") {
				let file = Bundle.main.url(forResource: "apple", withExtension: "jpeg")!
				PortalToWatch.instance.send(file)
			}
		}
		if let message = portal.mostRecentMessage {
			Text(message.description)
				.padding()
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
