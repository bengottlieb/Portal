//
//  DevicePortal+Sending.swift
//  
//
//  Created by Ben Gottlieb on 2/2/21.
//

import Foundation
import WatchConnectivity

@available(iOS 13.0, watchOS 7.0, *)
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
	
	func canSendMessage(completion: ((Error?) -> Void)?) -> Bool {
		if !self.isActive {
			print("Trying to send a message to an inactive counterpart")
			completion?(PortalError.sessionIsInactive)
			return false
		}

		if !self.isReachable {
			print("Trying to send a message to an unreachable counterpart")
			completion?(PortalError.counterpartIsNotReachable)
			return false
		}
		return true
	}
	
	func send(_ message: PortalMessage, completion: ((Error?) -> Void)? = nil) {
		if !canSendMessage(completion: completion) { return }
		
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
		if !canSendMessage(completion: completion) { return }

		let message = PortalMessage(.string, [PortalMessage.Kind.string.rawValue: string])
		send(message, completion: completion)
	}
	
	func send(userInfo: [String: Any]) {
		if !canSendMessage(completion: nil) { return }

		DispatchQueue.main.async { self.isTransferingUserInfo = true }
		session?.transferUserInfo(userInfo)
	}

}
