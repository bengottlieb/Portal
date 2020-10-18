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
	@Binding var image: Image?
	
	var body: some View {
		VStack() {
			if let kind = portal.mostRecentMessage?.kind.rawValue {
				Text(kind)
					.padding()
			}
			if let image = self.image {
				image
			}
			HStack() {
				Button("Ping") {
					PortalToPhone.instance.send(PortalMessage(.ping))
				}
				Button("Pong") {
					PortalToPhone.instance.send(PortalMessage(.pong))
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(image: .constant(nil))
	}
}
