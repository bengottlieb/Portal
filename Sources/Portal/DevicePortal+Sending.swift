//
//  File.swift
//  
//
//  Created by Ben Gottlieb on 2/2/21.
//

import Foundation
import WatchConnectivity

public extension DevicePortal {
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
		let errorHandler: ErrorHandler = { err in
				DispatchQueue.main.async { self.recentSendError = err }
				message.completion?(.failure(err))
				completion?(err)
		}
		
		if message.completion == nil && completion == nil {
			session?.sendMessage(payload, replyHandler: nil, errorHandler: errorHandler)
		} else {
			session?.sendMessage(payload, replyHandler: { result in
				message.completion?(.success(result))
				completion?(nil)
			}, errorHandler: errorHandler)
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

	func handleCompleted(file: WCSessionFileTransfer, error: Error?) {
		if let index = self.pendingTransfers.firstIndex(where: { $0.transfer == file }) {
			self.pendingTransfers[index].completion?(error)
			self.pendingTransfers.remove(at: index)
		}
	}
	
	func handleIncoming(message payload: [String: Any], reply: (([String: Any]) -> Void)? = nil) {
		if let message = PortalMessage(payload: payload, completion: reply) {
			DispatchQueue.main.async { self.mostRecentMessage = message }
			
			if self.messageHandler?.didReceive(message: message) != true, let rep = reply {
				rep([ "success": true ])
			} else {
				reply?(["success": false])
			}
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
