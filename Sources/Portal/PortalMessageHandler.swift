//
//  PortalMessageHandler.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation

public protocol PortalMessageHandler {
	func didReceive(message: PortalMessage) -> [String: Any]?
	func didReceive(file: URL, fileType: PortalFileKind?, metadata: [String: Any]?, completion: @escaping () -> Void)
	func didReceive(userInfo: [String: Any])
}
