//
//  DevicePortal+Receiving.swift
//  
//
//  Created by Ben Gottlieb on 2/2/21.
//

import Foundation
import WatchConnectivity

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
		let cachedLocation = tempFileDirectory.appendingPathComponent("\(UUID().uuidString).\(file.fileURL.pathExtension)")
		do {
			try FileManager.default.moveItem(at: file.fileURL, to: cachedLocation)
			self.messageHandler.didReceive(file: cachedLocation, metadata: file.metadata) {
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

	func handleIncoming(message payload: [String: Any], reply: (([String: Any]) -> Void)? = nil) {
		if let message = PortalMessage(payload: payload, completion: reply) {
			DispatchQueue.main.async { self.mostRecentMessage = message }
			
			if self.handle(builtInMessage: message) {
				reply?(["success": true])
				return
			}
			
			if self.messageHandler.didReceive(message: message) != true, let rep = reply {
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
	
	func handle(builtInMessage message: PortalMessage) -> Bool {
		switch message.kind {
		case .heartRate:
			if let rate = message.heartRate {
				self.heartRate = rate
			}
			return true
			
		default: return false
		}
	}
}
