//
//  ContentView.swift
//  PortalHarness_Watch Extension
//
//  Created by Ben Gottlieb on 10/17/20.
//

import SwiftUI
import Portal

extension PortalMessage.Kind {
	public static let pong = PortalMessage.Kind(rawValue: "_pong")
}

struct ContentView: View {
	@ObservedObject var portal = PortalToPhone.instance
	@EnvironmentObject var router: ImageRouter

	var body: some View {
		ScrollView() {
			VStack() {
				Text(portal.isReachable ? "Reachable" : "Unreachable")
					.foregroundColor(portal.isReachable ? .green : .red)
				if let context = portal.counterpartApplicationContext {
					Text(context.description)
				}
				if let message = portal.mostRecentMessage {
					Text(message.description)
						.padding()
				}
				if let image = router.image {
					image
				}
				Button("Send Image") {
					let file = Bundle.main.url(forResource: "apple", withExtension: "jpeg")!
					PortalToPhone.instance.send(file)
				}
				
				Button("Send Context") {
					portal.applicationContext = ["C": "d"]
				}

				Button("Send User Info") {
					portal.send(userInfo: ["C": "d"])
				}
				HStack() {
					Button("Ping") {
						PortalToPhone.instance.send("message Ping")
					}
					Button("Pong") {
						PortalToPhone.instance.send("Pong message")
					}
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
