//
//  DevicePortal.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation
import WatchConnectivity
import Combine
import Studio

public enum PortalError: Error { case fileTransferDoesntWorkInTheSimulator, sessionIsInactive, counterpartIsNotReachable }

typealias ErrorHandler = (Error) -> Void

@available(iOS 13.0, watchOS 7.0, *)
public class DevicePortal: NSObject, ObservableObject {
	static public var instance: DevicePortal!
	
	public var session: WCSession?
	public var messageHandler: PortalMessageHandler

	public var mostRecentMessage: PortalMessage? { didSet { objectChanged() }}
	public internal(set) var applicationContext: [String: Any]? { didSet { applicationContextDidChange() }}
	public internal(set) var counterpartApplicationContext: [String: Any]?
	public var isTransferingUserInfo = false { didSet { objectChanged() }}

	public var activationError: Error? { didSet { objectChanged() }}
	public var recentSendError: Error? { didSet { objectChanged() }}

	public var pendingTransfers: [TransferringFile] = []
	public var isActive: Bool { session?.activationState == .activated }
	public var isReachable: Bool { session?.isReachable ?? false }
	public internal(set) var isCounterpartActive = false { didSet { objectChanged() }}
	public var isApplicationActive: Bool? { didSet { if isApplicationActive != oldValue { applicationContextDidChange() }}}
	public var heartRate: Int? { didSet { objectChanged() }}
	
	#if os(iOS)
		public var isWatchAppInstalled: Bool { false }
		public var isPaired: Bool { false }
	#endif
	
	init(messageHandler: PortalMessageHandler) {
		self.messageHandler = messageHandler

		super.init()
	}
	
	public struct Notifications {
		public static let heartRateReceived = Notification.Name("DevicePortal.heartRateReceived")
	}
	
	@discardableResult
	public func connect() -> Bool {
		if !WCSession.isSupported() { return false }
		session = WCSession.default
		session?.delegate = self
		session?.activate()
		
		if let context = session?.receivedApplicationContext { received(context: context) }
		return true
	}

	public var tempFileDirectory = FileManager.default.temporaryDirectory

	static public let success: [String: Any] = ["success": "true"]
	static public let failure: [String: Any] = ["failure": "true"]
}

@available(iOS 13.0, watchOS 7.0, *)
extension DevicePortal: WCSessionDelegate {
	#if os(iOS)
		public func sessionDidBecomeInactive(_ session: WCSession) {
			objectChanged()
		}
		
		public func sessionDidDeactivate(_ session: WCSession) {
			objectChanged()
		}
	
		public func sessionWatchStateDidChange(_ session: WCSession) {
			objectChanged()
		}
	#endif
	
	public func sessionReachabilityDidChange(_ session: WCSession) {
		self.objectChanged()
	}
	
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		DispatchQueue.main.async {
			self.activationError = error
			self.objectChanged()
		}
	}
	
	func objectChanged() {
		DispatchQueue.main.async { self.objectWillChange.send() }
	}
	
	func applicationContextDidChange() {
		do {
			var context = self.applicationContext ?? [:]
			context[Keys.hash] = Date().timeIntervalSince1970
			if let isActive = isApplicationActive { context[Keys.isActive] = isActive }
			try self.session?.updateApplicationContext(context)
		} catch {
			DispatchQueue.main.async { self.recentSendError = error }
		}
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

@available(iOS 13.0, watchOS 7.0, *)
extension DevicePortal {
	struct Keys {
		static let hash = "_hashKey"
		static let isActive = "_active"
		static let fileKind = "_kind"
		static let fileName = "_name"
	}
}
