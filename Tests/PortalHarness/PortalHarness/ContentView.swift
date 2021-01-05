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
		VStack() {
			Text(portal.isReachable ? "Reachable" : "Unreachable")
				.foregroundColor(portal.isReachable ? .green : .red)
			if let context = portal.counterpartApplicationContext {
				Text(context.description)
			}
			Button("Notify") {
				UserNotificationManager.instance.notify(title: "Hello", body: "I'm a notification!", in: 5)
			}

			Button("Ping") {
				portal.send("message ping")
			}

			Button("Pong") {
				portal.send("pong message")
			}
			
			if let image = router.image {
				image
			}
			Button("Send Image") {
				let file = Bundle.main.url(forResource: "apple", withExtension: "jpeg")!
				portal.send(file)
			}
			Button("Send User Info") {
				portal.send(userInfo: ["a": "B"])
			}

			Button("Send Context") {
				portal.applicationContext = ["A": "b"]
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
