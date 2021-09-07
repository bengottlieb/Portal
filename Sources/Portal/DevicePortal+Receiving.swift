//
//  DevicePortal+Receiving.swift
//  
//
//  Created by Ben Gottlieb on 2/2/21.
//

import Foundation
import Studio
import WatchConnectivity

@available(iOS 13.0, watchOS 7.0, *)
extension WCSessionFile {
	var fileKind: PortalFileKind? {
		guard let raw = metadata?[DevicePortal.Keys.fileKind] as? String else { return nil }
		return PortalFileKind(rawValue: raw)
	}
	
	var fileName: String {
		guard let name = metadata?[DevicePortal.Keys.fileName] as? String else { return fileURL.lastPathComponent }
		return name
	}
}

@available(iOS 13.0, watchOS 7.0, *)
public extension DevicePortal {
	func session(_ session: WCSession, didReceiveMessage payload: [String : Any]) {
		handleIncoming(message: payload)
	}
	
	func session(_ session: WCSession, didReceiveMessage payload: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		handleIncoming(message: payload, reply: replyHandler)
	}

	func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
		self.receiveCompleted(file: fileTransfer, error: error)
	}

	func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		self.received(context: applicationContext)
	}
	
	func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
		self.messageHandler.didReceive(userInfo: userInfo)
	}

	func session(_ session: WCSession, didReceive file: WCSessionFile) {
		let cachedLocation = FileManager.default.uniqueURL(in: tempFileDirectory, base: file.fileName)
		do {
			try FileManager.default.moveItem(at: file.fileURL, to: cachedLocation)
			self.messageHandler.didReceive(file: cachedLocation, fileType: file.fileKind, metadata: file.metadata) {
				DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
					try? FileManager.default.removeItem(at: cachedLocation)
				}
			}
		} catch {
			print("Error when copying received file: \(error)")
		}
	}

	func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
		DispatchQueue.main.async {
			self.isTransferingUserInfo = false
			if error != nil { self.recentSendError = error }
		}
	}
	
	func receiveCompleted(file: WCSessionFileTransfer, error: Error?) {
		if let index = self.pendingTransfers.firstIndex(where: { $0.transfer == file }) {
			self.pendingTransfers[index].completion?(error)
			self.pendingTransfers.remove(at: index)
		}
	}

	func handleIncoming(message payload: [String: Any], reply: @escaping (([String: Any]) -> Void) = { _ in }) {
		self.processingIncomingMessage = true
		let message = PortalMessage(payload: payload, completion: reply)
		DispatchQueue.main.async { self.mostRecentMessage = message }
		if logIncomingMessages { recordLog(message.kind.rawValue, kind: .incoming) }

		lastMessageKind = message.kind
		if self.handle(builtInMessage: message) {
			reply(DevicePortal.success)
			self.processingIncomingMessage = false
			return
		}
		
		if let result = self.messageHandler.didReceive(message: message) {
			reply(result)
		} else {
			reply(DevicePortal.failure)
		}
		self.processingIncomingMessage = false
	}
	
	func received(context: [String: Any], restoring: Bool = false) {
		var ctx = context
		if let active = ctx[Keys.isActive] as? Bool { self.isCounterpartActive = active }
		ctx.removeValue(forKey: Keys.isActive)
		ctx.removeValue(forKey: Keys.hash)
		if !restoring, DevicePortal.cacheContexts {
			self.cachedContext = context
		}
		DispatchQueue.main.async {
			self.objectWillChange.send()
			self.counterpartApplicationContext = ctx
		}
	}
	
	func handle(builtInMessage message: PortalMessage) -> Bool {
		switch message.kind {
		case .ping:
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notifications.pingReceived, object: nil)
			}
			return true
			
		case .logMessage:
			if let log = message.logMessage {
				DispatchQueue.main.async {
					self.objectWillChange.send()
					self.recordLog(log, at: message.createdAt)
				}
			}
			return true

		#if os(iOS)
			case .batteryLevel:
				if let level = message.batteryLevel { watchBatteryLevel = level }
				return true
		#endif
				
		case .heartRate:
			if let rate = message.heartRate {
				self.heartRate = rate
				DispatchQueue.main.async { NotificationCenter.default.post(name: Notifications.heartRateReceived, object: rate) }
			}
			return true
			
		default: return false
		}
	}
}

@available(iOS 13.0, watchOS 7.0, *)
extension DevicePortal {
	static let cachedContextURL = FileManager.cacheURL(at: "watch/cachedContext.json")
	var cachedContext: [String: Any]? {
		get {
			guard let data = try? Data(contentsOf: Self.cachedContextURL) else { return nil }
			guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
			return json as? [String: Any]
		}
		
		set {
			guard let json = newValue else {
				try? FileManager.default.removeItem(at: Self.cachedContextURL)
				return
			}
			let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
			try? data?.write(to: Self.cachedContextURL)
		}
	}
}
