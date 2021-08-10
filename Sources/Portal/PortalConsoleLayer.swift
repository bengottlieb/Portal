//
//  PortalConsoleLayer.swift
//  
//
//  Created by Ben Gottlieb on 7/13/21.
//

import SwiftUI

@available(iOS 14.0, watchOS 7.0, *)
class ConsoleManager: ObservableObject {
	static let instance = ConsoleManager()
	
	@Published var showConsole = false
}

@available(iOS 14.0, watchOS 7.0, *)
public struct PortalConsoleLayer: View {
	@State var yOffset: CGFloat = 0
	@State var dragOffset: CGFloat = 0
	@State var isDraggable = false
	
	public static var showConsole: Bool {
		get { ConsoleManager.instance.showConsole }
		set { ConsoleManager.instance.showConsole = newValue }
	}
	
	@ObservedObject var manager = ConsoleManager.instance
	
	public init() {
		
	}
	
	public var body: some View {
		if ConsoleManager.instance.showConsole {
			ZStack() {
				Color.clear
				
				VStack() {
					Spacer()
					
					if isDraggable {
						PortalConsoleView()
							.padding()
							.padding(.bottom, 60)
							.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
								dragOffset = value.translation.height
							}.onEnded { value in
								yOffset += dragOffset
								dragOffset = 0
							})
							.offset(y: yOffset + dragOffset)
					} else {
						PortalConsoleView()
							.padding()
							.padding(.bottom, 60)
							.offset(y: yOffset + dragOffset)
					}
				}
			}
		}
	}
}
