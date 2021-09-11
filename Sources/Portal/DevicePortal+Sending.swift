//
//  DevicePortal+Sending.swift
//  
//
//  Created by Ben Gottlieb on 2/2/21.
//

import Foundation
import WatchConnectivity

#if canImport(WatchKit)
import WatchKit

@available(iOS 13.0, watchOS 7.0, *)
public extension DevicePortal {
	func sendBatteryLevel() {
		let device = WKInterfaceDevice.current()
		guard device.isBatteryMonitoringEnabled else { return }
		
		send(PortalMessage(.batteryLevel, ["level": device.batteryLevel]))
	}
}

#endif

public struct PortalFileKind: Equatable {
	public let rawValue: String
	public init(rawValue: String) {
		self.rawValue = rawValue
	}
	
	public static func ==(lhs: PortalFileKind, rhs: PortalFileKind) -> Bool { lhs.rawValue == rhs.rawValue }
}


@available(iOS 13.0, watchOS 7.0, *)
public extension DevicePortal {
	func startPinging(interval: TimeInterval = 1.0) {
		DispatchQueue.main.async {
			self.pingTimer?.invalidate()
			
			self.pingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _  in
				if self.isReachable { self.send(PortalMessage(.ping)) }
			}
		}
	}
	
	func stopPinging() {
		DispatchQueue.main.async {
			self.pingTimer?.invalidate()
		}
	}
	
	func send(raw dictionary: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil, errorHandler: ((Error?) -> Void)? = nil) {
		guard let session = session else {
			errorHandler?(PortalError.sessionIsMissing)
			return
		}
		session.sendMessage(dictionary, replyHandler: replyHandler, errorHandler: errorHandler)
	}

	func send(_ file: URL, fileType: PortalFileKind? = nil, metadata: [String: Any]? = nil, completion: ((Error?) -> Void)? = nil) {
		var meta = metadata ?? [:]
		if let type = fileType { meta[Keys.fileKind] = type.rawValue }
		meta[Keys.fileName] = file.lastPathComponent
		#if targetEnvironment(simulator)
			completion?(PortalError.fileTransferDoesntWorkInTheSimulator)
		#else
			if let transfer = self.session?.transferFile(file, metadata: meta) {
				let info = TransferringFile(transfer: transfer, completion: completion)
				pendingTransfers.append(info)
			}
		#endif
	}
	
	func checkLatency(payload: [String: Any]? = nil, completion: ((Result<TimeInterval, Error>) -> Void)? = nil) {
		let started = Date()
		if let body = payload {
			do {
				let json = try JSONSerialization.data(withJSONObject: body, options: [])
				if DevicePortal.verboseErrorMessages { print("Sending \(json.count) bytes") }
			} catch {
				completion?(.failure(error))
				return
			}
		}
		send(PortalMessage(.ping, payload) { error in
			let time = abs(started.timeIntervalSinceNow)
			DispatchQueue.main.async {
				self.lastReportedLatency = time
			}
			completion?(.success(time))
		}) { error in
			if let err = error { completion?(.failure(err)) }
		}
	}
	
	func canSendMessage(completion: ((Error) -> Void)?) -> Bool {
		if !self.isActive {
			if DevicePortal.verboseErrorMessages { print("Trying to send a message to an inactive counterpart") }
			completion?(PortalError.sessionIsInactive)
			return false
		}

		if !self.isReachable {
			if DevicePortal.verboseErrorMessages { print("Trying to send a message to an unreachable counterpart") }
			completion?(PortalError.counterpartIsNotReachable)
			return false
		}
		return true
	}
	
	func send(_ messageKind: PortalMessage.Kind, completion: ((Error?) -> Void)? = nil) {
		self.send(PortalMessage(messageKind), completion: completion)
	}

	func send(_ log: String) {
		self.send(PortalMessage(log: log))
	}
	
	func send(_ message: PortalMessage, completion: ((Error?) -> Void)? = nil) {
		if processingIncomingMessage {
			print("\(Date()) Still processing incoming (\(lastMessageKind)), retrying in 0.1")
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				self.send(message, completion: completion)
				return
			}
		}
		guard let session = self.session, canSendMessage(completion: completion) else {
			if Self.verboseErrorMessages { print("Can't send message \(message.kind)") }
			completion?(self.session == nil ? PortalError.sessionIsMissing : PortalError.cantSendMessage)
			return }
		
		if logOutgoingMessages { recordLog(message.kind.rawValue, kind: .outgoing) }
		let payload = message.payload
		let errorHandler: ErrorHandler = { err in
				DispatchQueue.main.async { self.recentSendError = err }
				message.completion?(.failure(err))
				completion?(err)
		}
		
		if message.completion == nil && completion == nil {
			session.sendMessage(payload, replyHandler: nil, errorHandler: errorHandler)
		} else {
			session.sendMessage(payload, replyHandler: { result in
				message.completion?(.success(result))
				completion?(nil)
			}, errorHandler: errorHandler)
		}
	}
	
	func send(userInfo: [String: Any]) {
		guard let session = session, canSendMessage(completion: nil) else { return }

		DispatchQueue.main.async { self.isTransferingUserInfo = true }
		session.transferUserInfo(userInfo)
	}

}
