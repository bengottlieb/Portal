//
//  PortalMessage.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Suite

public typealias SendCallback = (Result<[String: Any], Error>) -> Void

public struct PortalMessage: CustomStringConvertible, Identifiable {
	public struct Kind: Equatable {
		public let rawValue: String
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		public static let unknown = Kind(rawValue: "_unknown")
		public static let none = Kind(rawValue: "_none")
		public static let heartbeat = Kind(rawValue: "_heartbeat")
		public static let heartRate = Kind(rawValue: "_heartRate")
		public static let heartbeatResponse = Kind(rawValue: "_heartbeatResponse")
		public static let string = Kind(rawValue: "_string")
		public static let didResignActive = Kind(rawValue: "_inactive")
		public static let didBecomeActive = Kind(rawValue: "_active")
		public static let logMessage = Kind(rawValue: "_log")
		public static let batteryLevel = Kind(rawValue: "_battery")

		public static func ==(lhs: Kind, rhs: Kind) -> Bool { lhs.rawValue == rhs.rawValue }
	}
	
	public var description: String {
		if self.kind == .string, let string = self.string { return string }
		return "\(kind.rawValue): \(body ?? [:])"
	}
	
	public var string: String? { self.body?[Kind.string.rawValue] as? String }
	
	public let kind: Kind
	public let body: [String: Any]?
	public let completion: SendCallback?
	public let createdAt: Date
	public var id: String
	
	public static var heartbeat: PortalMessage { PortalMessage(.heartbeat) }

	public init(_ kind: Kind, _ body: [String: Any]? = nil, completion: SendCallback? = nil) {
		self.kind = kind
		self.body = body
		self.createdAt = Date()
		self.completion = completion
		self.id = body?["id"] as? String ?? UUID().uuidString
	}
	
	init(payload: [String: Any], completion: (([String: Any]) -> Void)?) {
		self.completion = { result in
			if let success = try? result.get() { completion?(success) }
		}

		guard let kind = payload["kind"] as? String, let date = payload["date"] as? TimeInterval else {
			id = UUID().uuidString
			createdAt = Date()
			self.kind = .unknown
			body = payload
			return
		}
		
		self.createdAt = Date(timeIntervalSinceReferenceDate: date)
		self.kind = Kind(rawValue: kind)
		self.body = payload["body"] as? [String: Any]
		self.id = (payload["body"] as? [String: Any])?["id"] as? String ?? UUID().uuidString
	}

	public init(log: String) {
		self.init(.logMessage, ["log": log])
	}
	public var logMessage: String? { body?["log"] as? String }
	
	public init(heartRate: Int, date: Date) {
		self.init(.heartRate, ["rate": heartRate, "date": date.timeIntervalSinceReferenceDate])
	}

	public var heartRate: Int? { body?["rate"] as? Int }
	public var date: Date? {
		if let time = body?["date"] as? TimeInterval {
			return Date(timeIntervalSinceReferenceDate: time)
		}
		return nil
	}
	var payload: [String: Any] {
		var payload: [String: Any] = ["kind": kind.rawValue, "date": createdAt.timeIntervalSinceReferenceDate]
		
		if let body = self.body {
			payload["body"] = body
		}
		
		return payload
	}
	
	public var batteryLevel: Double? { body?["level"] as? Double }
	
	public init?<Payload: Codable>(kind: Kind, payload: Payload) {
		do {
			let json = try CodableWrapper(body: payload).asJSON()
			self.init(kind, json)
		} catch {
			logg(error: error, "Failed to encode: \(payload)")
			return nil
		}
	}

	public struct CodableWrapper<Payload: Codable>: Codable {
		public let body: Payload
	}
}
