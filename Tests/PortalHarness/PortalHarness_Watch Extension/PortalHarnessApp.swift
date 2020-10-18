//
//  PortalHarnessApp.swift
//  PortalHarness_Watch Extension
//
//  Created by Ben Gottlieb on 10/17/20.
//

import SwiftUI
import Portal

@main
struct PortalHarnessApp: App, PortalMessageHandler {
	@State var image: Image?
	func didReceive(message: PortalMessage) {
		message.completion?(.success(["success": true]))
	}
	
	func didReceive(file: URL, metadata: [String: Any]?) {
		if let image = UIImage(contentsOfFile: file.path) {
			self.image = Image(uiImage: image)
		}
	}

	init() {
		PortalToPhone.instance.setup(messageHandler: self)
	}
	
	@SceneBuilder var body: some Scene {
		WindowGroup {
			NavigationView {
				ContentView(image: $image)
			}
		}
		
		WKNotificationScene(controller: NotificationController.self, category: "myCategory")
	}
}
