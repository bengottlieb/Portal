//
//  PortalToWatch.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

#if os(iOS)

import Foundation
import SwiftUI
import WatchConnectivity
import Combine

public class PortalToWatch: NSObject, ObservableObject, DevicePortal {
	public static let instance = PortalToWatch()
	
	@Published public var activationError: Error?
	@Published public var messageSendError: Error?
	@Published public var mostRecentMessage: PortalMessage?
	
	public var messageHandler: PortalMessageHandler?
	public let session = WCSession.default
	public var pendingTransfers: [TransferringFile] = []
	public var tempFileDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, [.userDomainMask], true).first!)

	override init() {
		super.init()
		
		session.delegate = self
		session.activate()
		
	}
}

extension PortalToWatch: WCSessionDelegate {
	public func sessionDidBecomeInactive(_ session: WCSession) {
		
	}
	
	public func sessionDidDeactivate(_ session: WCSession) {
		
	}
	
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		
		DispatchQueue.main.async { self.activationError = error }
	}
	
	public func sessionReachabilityDidChange(_ session: WCSession) {
		print("Reachability changed: \(session.isReachable)")
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
}

#endif
