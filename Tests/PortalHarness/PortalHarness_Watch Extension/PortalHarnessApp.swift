//
//  PortalHarnessApp.swift
//  PortalHarness_Watch Extension
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

	func didReceive(message: PortalMessage) {
		message.completion?(.success(["success": true]))
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
		PortalToPhone.instance.setup(messageHandler: self)
	}
	
	@SceneBuilder var body: some Scene {
		WindowGroup {
			NavigationView {
				ContentView()
					.environmentObject(router)
			}
		}
		
		WKNotificationScene(controller: NotificationController.self, category: "myCategory")
	}
}
