//
//  PortalLogView.swift
//  
//
//  Created by Ben Gottlieb on 7/7/21.
//

import SwiftUI

@available(iOS 14.0, watchOS 7.0, *)
public protocol PortalLogViewSource: ObservableObject {
	var messages: [DevicePortal.LoggedMessage] { get }
}

@available(iOS 14.0, watchOS 7.0, *)
extension DevicePortal: PortalLogViewSource {
	public var messages: [DevicePortal.LoggedMessage] { recentMessages }
}

@available(iOS 14.0, watchOS 7.0, *)
public struct PortalLogView<Source: PortalLogViewSource>: View {
	@ObservedObject var source: Source
	let maxLineCount: Int?
	let showControls: Bool

	public init(source: Source, maxLineCount: Int? = 4, includingControls: Bool? = nil) {
		self.maxLineCount = maxLineCount
		self.source = source
		
		if let include = includingControls {
			showControls = include
		} else {
			#if os(iOS)
				showControls = true
			#else
				showControls = false
			#endif
		}
	}
	
	var messages: [DevicePortal.LoggedMessage] {
		let all = source.messages
		guard let count = maxLineCount, count < all.count, !all.isEmpty else { return all }
		
		return Array(all[all.count - count..<all.count])
	}

	let distantFuture = Date.distantFuture
	public var body: some View {
		VStack(spacing: 0) {
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
				.onReceive(source.objectWillChange) { _ in
					withAnimation(.linear(duration: 0.1)) {
						scroll.scrollTo(distantFuture, anchor: .bottom)
					}
				}
			}
			if showControls { PortalControlsBar() }
		}
		.background(Color.black)
		.foregroundColor(.green)
		.cornerRadius(5)
	}
}

@available(iOS 14.0, watchOS 7.0, *)
extension PortalLogView where Source == DevicePortal {
	public init(maxLineCount: Int? = 4, includingControls: Bool = true) {
		source = DevicePortal.instance!
		self.maxLineCount = maxLineCount
		self.showControls = includingControls
	}
}

@available(iOS 14.0, watchOS 7.0, *)
struct PortalLogView_Previews: PreviewProvider {
	static var previews: some View {
		PortalLogView()
	}
}
