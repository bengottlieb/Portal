//
//  DevicePortal.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation
import WatchConnectivity

public enum PortalError: Error { case fileTransferDoesntWorkInTheSimulator, sessionIsInactive }

typealias ErrorHandler = (Error) -> Void

let hashKey = "_hashKey"

public var CounterpartPortal: DevicePortal!

public protocol DevicePortal: class {
	func send(_ message: PortalMessage, completion: ((Error?) -> Void)?)
	func send(_ file: URL, metadata: [String: Any]?, completion: ((Error?) -> Void)?)
	func send(_ string: String, completion: ((Error?) -> Void)?)

	var session: WCSession? { get set }
	var recentSendError: Error? { get set }
	var mostRecentMessage: PortalMessage? { get set }
	var applicationContext: [String: Any]? { get set }
	var counterpartApplicationContext: [String: Any]? { get set }
	var isTransferingUserInfo: Bool { get set }

	var messageHandler: PortalMessageHandler? { get set }
	var pendingTransfers: [TransferringFile] { get set }
	var isActive: Bool { get set }
}

public extension DevicePortal {
	var isReachable: Bool { session?.isReachable ?? false }
}

public extension DevicePortal where Self: WCSessionDelegate {
	func applicationContextDidChange() {
		do {
			if var context = self.applicationContext {
				context[hashKey] = UUID().uuidString
				try self.session?.updateApplicationContext(context)
			}
		} catch {
			DispatchQueue.main.async { self.recentSendError = error }
		}
	}

	func setup(messageHandler: PortalMessageHandler) {
		self.messageHandler = messageHandler

		if !WCSession.isSupported() { return }
		session = WCSession.default
		session?.delegate = self
		session?.activate()
		
		self.counterpartApplicationContext = session?.receivedApplicationContext
	}
}

public struct TransferringFile: Equatable, Identifiable {
	public let id = UUID()
	let transfer: WCSessionFileTransfer
	let completion: ((Error?) -> Void)?
	
	public static func ==(lhs: TransferringFile, rhs: TransferringFile) -> Bool {
		lhs.id == rhs.id
	}
}
