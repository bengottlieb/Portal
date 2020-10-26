//
//  PortalToPhone.swift
//  Portal_Watch
//
//  Created by Ben Gottlieb on 10/17/20.
//

#if os(watchOS)
#if canImport(Combine)

import Foundation
import SwiftUI
import WatchKit
import WatchConnectivity
import Combine

@available(iOS 13.0, watchOS 7.0, *)
public class PortalToPhone: NSObject, ObservableObject, DevicePortal {
	public static let instance = PortalToPhone()
	
	@Published public var activationError: Error?
	@Published public var recentSendError: Error?
	@Published public var mostRecentMessage: PortalMessage?
	@Published public var applicationContext: [String: Any]? { didSet { applicationContextDidChange() }}
	@Published public var counterpartApplicationContext: [String: Any]?
	public var isReachable: Bool { session?.isReachable ?? false }
	@Published public var isTransferingUserInfo = false

	public var messageHandler: PortalMessageHandler?
	public var session: WCSession?
	public var pendingTransfers: [TransferringFile] = []
	public var tempFileDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, [.userDomainMask], true)[0])
}

@available(iOS 13.0, watchOS 7.0, *)
extension PortalToPhone: WCSessionDelegate {
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		DispatchQueue.main.async { self.activationError = error }
	}
	
	public func sessionReachabilityDidChange(_ session: WCSession) {
		DispatchQueue.main.async { self.objectWillChange.send() }
	}
	
	public func session(_ session: WCSession, didReceiveMessage payload: [String : Any]) {
		handleIncoming(message: payload)
	}
	
	public func session(_ session: WCSession, didReceiveMessage payload: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		handleIncoming(message: payload, reply: replyHandler)
	}
	
	public func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
		self.handleCompleted(file: fileTransfer, error: error)
	}

	public func session(_ session: WCSession, didReceive file: WCSessionFile) {
		let cachedLocation = tempFileDirectory.appendingPathComponent("\(UUID().uuidString).\(file.fileURL.pathExtension)")
		do {
			try FileManager.default.moveItem(at: file.fileURL, to: cachedLocation)
			self.messageHandler?.didReceive(file: cachedLocation, metadata: file.metadata) {
				DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
					try? FileManager.default.removeItem(at: cachedLocation)
				}
			}
		} catch {
			print("Error when copying received file: \(error)")
		}
	}
	
	public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
		self.received(context: applicationContext)
	}
	
	public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
		self.messageHandler?.didReceive(userInfo: userInfo)
	}
	
	public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
		DispatchQueue.main.async {
			self.isTransferingUserInfo = false
			if error != nil { self.recentSendError = error }
		}
	}
}

#endif
#endif
