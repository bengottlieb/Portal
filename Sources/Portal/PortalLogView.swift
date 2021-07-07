//
//  PortalLogView.swift
//  
//
//  Created by Ben Gottlieb on 7/7/21.
//

import SwiftUI

@available(iOS 14.0, watchOS 7.0, *)
public struct PortalLogView: View {
	@ObservedObject var portal = DevicePortal.instance
	let maxLineCount: Int?

	public init(maxLineCount: Int? = 4) {
		self.maxLineCount = maxLineCount
	}
	
	var messages: [DevicePortal.LoggedMessage] {
		let all = portal.recentMessages
		guard let count = maxLineCount, count < all.count, !all.isEmpty else { return all }
		
		return Array(all[all.count - count..<all.count])
	}

	let distantFuture = Date.distantFuture
	public var body: some View {
		ScrollViewReader() { scroll in
			ScrollView() {
				VStack(spacing: 0) {
					ForEach(messages) { message in
						Text(message.text).id(message.id)
							.frame(maxWidth: .infinity, alignment: .leading)
							.font(.system(size: 12, design: .monospaced))
					}
					Color.black
						.frame(height: 2)
						.id(distantFuture)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(4)
			}
			.onReceive(portal.objectWillChange) { _ in
				withAnimation(.linear(duration: 0.1)) {
					scroll.scrollTo(distantFuture, anchor: .bottom)
				}
			}
		}
		.background(Color.black)
		.foregroundColor(.green)
		.cornerRadius(5)
	}
}

@available(iOS 14.0, watchOS 7.0, *)
struct PortalLogView_Previews: PreviewProvider {
	static var previews: some View {
		PortalLogView()
	}
}
