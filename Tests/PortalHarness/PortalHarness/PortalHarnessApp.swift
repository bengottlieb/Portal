//
//  PortalHarnessApp.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import SwiftUI
import Portal

class ImageRouter: ObservableObject {
	@Published var image: Image?
}

@main
struct PortalHarnessApp: App, PortalMessageHandler {
	let router = ImageRouter()
	
	func didReceive(userInfo: [String: Any]) {
		print(userInfo)
		UserNotificationManager.instance.notify(title: "Notification", body: "Received", when: Date(timeIntervalSinceNow: 1))
	}

	func didReceive(message: PortalMessage) -> [String: Any]? {
		print(message)
		UserNotificationManager.instance.notify(title: "Notification", body: "Received", when: Date(timeIntervalSinceNow: 1))
		return DevicePortal.success
	}
	
	func didReceive(file: URL, metadata: [String: Any]?, completion: @escaping () -> Void) {
		if let image = UIImage(contentsOfFile: file.path) {
			DispatchQueue.main.async {
				router.image = Image(uiImage: image)
				completion()
			}
		} else {
			completion()
		}
	}
	
	
	init() {
		PortalToWatch.instance.setup(messageHandler: self)
		UserNotificationManager.instance.setup()
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(router)
		}
	}
	
	
}
