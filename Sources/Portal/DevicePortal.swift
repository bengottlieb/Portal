//
//  DevicePortal.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation
import WatchConnectivity

public enum PortalError: Error { case fileTransferDoesntWorkInTheSimulator, sessionIsInactive }

let hashKey = "_hashKey"

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
}

public extension DevicePortal {
	var isActive: Bool { session?.activationState == WCSessionActivationState.activated }
	var isReachable: Bool { session?.isReachable == true }
	
	func send(_ file: URL, metadata: [String: Any]? = nil, completion: ((Error?) -> Void)? = nil) {
		#if targetEnvironment(simulator)
			completion?(PortalError.fileTransferDoesntWorkInTheSimulator)
		#else
			if let transfer = self.session?.transferFile(file, metadata: metadata) {
				let info = TransferringFile(transfer: transfer, completion: completion)
				pendingTransfers.append(info)
			}
		#endif
	}
	
	func checkLatency(payload: [String: Any]? = nil, completion: @escaping (Result<TimeInterval, Error>) -> Void) {
		let started = Date()
		if let body = payload {
			do {
				let json = try JSONSerialization.data(withJSONObject: body, options: [])
				print("Sending \(json.count) bytes")
			} catch {
				completion(.failure(error))
				return
			}
		}
		send(PortalMessage(.ping, payload) { error in
			completion(.success(abs(started.timeIntervalSinceNow)))
		}) { error in
			if let err = error { completion(.failure(err)) }
		}
	}
	
	func send(_ message: PortalMessage, completion: ((Error?) -> Void)? = nil) {
		if !self.isActive {
			completion?(PortalError.sessionIsInactive)
			return
		}
		let payload = message.payload
		let replyHandler: ([String: Any]) -> Void = { reply in message.completion?(.success(reply)) }
		let noReplyHandler = message.completion == nil && completion == nil
		
		session?.sendMessage(payload, replyHandler: noReplyHandler ? nil : replyHandler) { err in
			DispatchQueue.main.async { self.recentSendError = err }
			message.completion?(.failure(err))
			completion?(err)
		}
	}
	
	func send(_ string: String, completion: ((Error?) -> Void)? = nil) {
		let message = PortalMessage(.string, [PortalMessage.Kind.string.rawValue: string])
		send(message, completion: completion)
	}
	
	func send(userInfo: [String: Any]) {
		DispatchQueue.main.async { self.isTransferingUserInfo = true }
		session?.transferUserInfo(userInfo)
	}
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

	func handleCompleted(file: WCSessionFileTransfer, error: Error?) {
		if let index = self.pendingTransfers.firstIndex(where: { $0.transfer == file }) {
			self.pendingTransfers[index].completion?(error)
			self.pendingTransfers.remove(at: index)
		}
	}
	
	func handleIncoming(message payload: [String: Any], reply: (([String: Any]) -> Void)? = nil) {
		if let message = PortalMessage(payload: payload, completion: reply) {
			DispatchQueue.main.async { self.mostRecentMessage = message }
			
			if self.messageHandler?.didReceive(message: message) != true, let rep = reply { rep([ "success": true ]) }
		} else {
			reply?(["success": false])
		}
	}
	
	func received(context: [String: Any]) {
		var ctx = context
		ctx.removeValue(forKey: hashKey)
		DispatchQueue.main.async { self.counterpartApplicationContext = ctx }
	}
}

#if os(iOS)
public extension DevicePortal {
	var isPaired: Bool { session?.isPaired ?? false }
	var isWatchAppInstalled: Bool { session?.isWatchAppInstalled ?? false }
}
#endif

public struct TransferringFile: Equatable, Identifiable {
	public let id = UUID()
	let transfer: WCSessionFileTransfer
	let completion: ((Error?) -> Void)?
	
	public static func ==(lhs: TransferringFile, rhs: TransferringFile) -> Bool {
		lhs.id == rhs.id
	}
}
