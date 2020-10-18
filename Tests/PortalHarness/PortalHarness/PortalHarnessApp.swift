//
//  PortalHarnessApp.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import SwiftUI
import Portal

@main
struct PortalHarnessApp: App, PortalMessageHandler {
	@State var image: Image?
	
	func didReceive(message: PortalMessage) {
		print(message)
		message.completion?(.success(["success": true]))
	}
	
	func didReceive(file: URL, metadata: [String: Any]?) {
		if let image = UIImage(contentsOfFile: file.path) {
			self.image = Image(uiImage: image)
		}
	}

	
	init() {
		PortalToWatch.instance.setup(messageHandler: self)
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
	
	
}
