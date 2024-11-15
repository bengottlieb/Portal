//
//  DevicePortal.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation
import WatchConnectivity
import Combine
import Suite

public enum PortalError: Error { case fileTransferDoesntWorkInTheSimulator, sessionIsInactive, counterpartIsNotReachable, sessionIsMissing, cantSendMessage, noMessage }

typealias ErrorHandler = (Error) -> Void

@available(iOS 13.0, watchOS 7.0, *)
public class DevicePortal: NSObject, ObservableObject {
	static public var instance: DevicePortal!
	static public var cacheContexts = true
	static public var verboseErrorMessages = false
	public var previouslyReachable = false
	@Published public var lastHeartbeatReceivedAt = Date.distantPast

	public var session: WCSession?
	public var messageHandler: PortalMessageHandler
	public var recentMessages: [LoggedMessage] = []
	public var heartbeatTimer: Timer?
	
	@Published public var logOutgoingMessages = false
	@Published public var logIncomingMessages = false
	@Published public var lastReportedLatency: TimeInterval?

	public var mostRecentMessage: PortalMessage? { didSet { objectChanged() }}
	public internal(set) var applicationContext: [String: Any]?
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
	public var heartRateReceivedAt: Date?
	var isContextDirty = false
	var processingIncomingMessage = false
	var lastMessageKind = PortalMessage.Kind.none
	
	#if os(iOS)
		public var isWatchAppInstalled: Bool { false }
		public var isPaired: Bool { false }
		public var watchBatteryLevel: Double? { didSet { objectChanged() }}
	#endif
	
	init(messageHandler: PortalMessageHandler) {
		self.messageHandler = messageHandler

		super.init()
	}
	
	public struct Notifications {
		public static let heartRateReceived = Notification.Name("DevicePortal.heartRateReceived")
		public static let lostConnection = Notification.Name("DevicePortal.lostConnection")
		public static let restoredConnection = Notification.Name("DevicePortal.restoredConnection")
		public static let heartbeatReceived = Notification.Name("DevicePortal.heartbeatReceived")
	}
	
	@discardableResult
	public func connect() -> Bool {
		if !WCSession.isSupported() { return false }
		session = WCSession.default
		session?.delegate = self
		session?.activate()
		return true
	}

	public var tempFileDirectory = FileManager.default.temporaryDirectory

	static public let success: [String: Any] = ["success": "true"]
	static public let failure: [String: Any] = ["failure": "true"]
	
	public enum MessageKind { case incoming, outgoing, log }
	public struct LoggedMessage: Identifiable {
		public let text: String
		public let date: Date
		public var id: Date { date }
		public var kind: MessageKind
	}

	public func recordLog(_ message: String, at date: Date = Date(), kind: MessageKind = .log) {
		recentMessages.append(LoggedMessage(text: message, date: date, kind: kind))
	}
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
			var context = session.applicationContext
			if context.isEmpty, Self.cacheContexts, let cached = self.cachedContext { context = cached }
			if DevicePortal.verboseErrorMessages { logg("Initial context: \(context)") }

			self.received(context: context, restoring: true)
			if self.isContextDirty {
				self.applicationContextDidChange()
			}

			if let err = error { logg(error: err, "Failed to activate WCSession")}
			self.activationError = error
			self.objectChanged()
		}
	}
	
	func objectChanged() {
		if previouslyReachable, !isReachable {
			DispatchQueue.main.async { DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.lostConnection, object: nil) } }
		} else if !previouslyReachable, isReachable {
			DispatchQueue.main.async { DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.restoredConnection, object: nil) } }
		}
		previouslyReachable = isReachable

		DispatchQueue.main.async { self.objectWillChange.send() }
	}

	public func set(applicationContext: [String: Any]) {
		self.applicationContext = applicationContext
		isContextDirty = true
		applicationContextDidChange()
	}
	
	func applicationContextDidChange() {
		do {
			if !isActive, DevicePortal.verboseErrorMessages {
				if DevicePortal.verboseErrorMessages { logg("Not active, not updating context") }
				return
			}
			if DevicePortal.verboseErrorMessages { logg("updating context") }
			var context = self.applicationContext ?? [:]
			context[Keys.hash] = Date().timeIntervalSince1970
			if let isActive = isApplicationActive { context[Keys.isActive] = isActive }
			try self.session?.updateApplicationContext(context)
			isContextDirty = false
		} catch {
			DispatchQueue.main.async { self.recentSendError = error }
		}
	}
}

public struct TransferringFile: Equatable, Identifiable {
	public let id = UUID()
	let transfer: WCSessionFileTransfer
	let completion: ErrorCallback?
	
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
