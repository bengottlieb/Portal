//
//  DevicePortal.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation
import WatchConnectivity

public enum PortalError: Error { case fileTransferDoesntWorkInTheSimulator }

public protocol DevicePortal: class {
	func send(_ message: PortalMessage, completion: ((Error?) -> Void)?)
	func send(_ file: URL, metadata: [String: Any]?, completion: ((Error?) -> Void)?)
	
	var session: WCSession { get }
	var messageSendError: Error? { get set }
	var mostRecentMessage: PortalMessage? { get set }

	var messageHandler: PortalMessageHandler? { get set }
	var pendingTransfers: [TransferringFile] { get set }
}

public extension DevicePortal where Self: WCSessionDelegate {
	func setup(messageHandler: PortalMessageHandler) {
		self.messageHandler = messageHandler
	}
	
	func send(_ file: URL, metadata: [String: Any]? = nil, completion: ((Error?) -> Void)? = nil) {
		#if targetEnvironment(simulator)
			completion?(PortalError.fileTransferDoesntWorkInTheSimulator)
		#else
			let transfer = self.session.transferFile(file, metadata: metadata)
			let info = TransferringFile(transfer: transfer, completion: completion)
			pendingTransfers.append(info)
		#endif
	}
	
	func send(_ message: PortalMessage, completion: ((Error?) -> Void)? = nil) {
		let payload = message.payload
		let replyHandler: ([String: Any]) -> Void = { reply in message.completion?(.success(reply)) }
		
		session.sendMessage(payload, replyHandler: message.completion == nil ? nil : replyHandler) { err in
			DispatchQueue.main.async { self.messageSendError = err }
			message.completion?(.failure(err))
			completion?(err)
		}
	}
	
	func session(_ session: WCSession, didReceiveMessage payload: [String : Any]) {
		if let message = PortalMessage(payload: payload, completion: nil) {
			DispatchQueue.main.async { self.mostRecentMessage = message }
			self.messageHandler?.didReceive(message: message)
		}
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
			self.messageHandler?.didReceive(message: message)
		} else {
			reply?(["success": false])
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
