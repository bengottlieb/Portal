//
//  DevicePortal.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation
import WatchConnectivity
import Combine

public enum PortalError: Error { case fileTransferDoesntWorkInTheSimulator, sessionIsInactive }

typealias ErrorHandler = (Error) -> Void

let hashKey = "_hashKey"


@available(iOS 13.0, watchOS 7.0, *)
public class DevicePortal: NSObject, ObservableObject {
	static public var instance: DevicePortal!
	
	public var session: WCSession?
	public var messageHandler: PortalMessageHandler

	public var mostRecentMessage: PortalMessage? { didSet { objectChanged() }}
	public var applicationContext: [String: Any]? { didSet { applicationContextDidChange() }}
	public var counterpartApplicationContext: [String: Any]?
	public var isTransferingUserInfo = false { didSet { objectChanged() }}

	public var activationError: Error? { didSet { objectChanged() }}
	public var recentSendError: Error? { didSet { objectChanged() }}

	public var pendingTransfers: [TransferringFile] = []
	public var isActive: Bool { session?.activationState == .activated }
	public var isReachable: Bool { session?.isReachable ?? false }
	public var heartRate: Int? { didSet { objectChanged() }}
	
	init(messageHandler: PortalMessageHandler) {
		self.messageHandler = messageHandler

		super.init()

		if !WCSession.isSupported() { return }
		session = WCSession.default
		session?.delegate = self
		session?.activate()
		
		self.counterpartApplicationContext = session?.receivedApplicationContext
	}

	public var tempFileDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, [.userDomainMask], true)[0])
}

@available(iOS 13.0, watchOS 7.0, *)
extension DevicePortal: WCSessionDelegate {
	#if os(iOS)
		public func sessionDidBecomeInactive(_ session: WCSession) {
			self.sessionReachabilityDidChange(session)
		}
		
		public func sessionDidDeactivate(_ session: WCSession) {
			self.sessionReachabilityDidChange(session)
		}
	
		public func sessionWatchStateDidChange(_ session: WCSession) {
			self.sessionReachabilityDidChange(session)
		}
	#endif
	
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		DispatchQueue.main.async {
			self.activationError = error
			self.sessionReachabilityDidChange(session)
		}
	}
	
	public func sessionReachabilityDidChange(_ session: WCSession) {
		objectChanged()
	}
	
	func objectChanged() {
		DispatchQueue.main.async { self.objectWillChange.send() }
	}
	
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
}

public struct TransferringFile: Equatable, Identifiable {
	public let id = UUID()
	let transfer: WCSessionFileTransfer
	let completion: ((Error?) -> Void)?
	
	public static func ==(lhs: TransferringFile, rhs: TransferringFile) -> Bool {
		lhs.id == rhs.id
	}
}
