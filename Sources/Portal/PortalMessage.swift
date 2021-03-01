//
//  PortalMessage.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation

public typealias SendCallback = (Result<[String: Any], Error>) -> Void

public struct PortalMessage: CustomStringConvertible, Identifiable {
	public struct Kind: Equatable {
		public let rawValue: String
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		public static let none = Kind(rawValue: "_none")
		public static let ping = Kind(rawValue: "_ping")
		public static let heartRate = Kind(rawValue: "_heartRate")
		public static let pingResponse = Kind(rawValue: "_pingResponse")
		public static let string = Kind(rawValue: "_string")
		public static let didResignActive = Kind(rawValue: "_inactive")
		public static let didBecomeActive = Kind(rawValue: "_active")

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
	
	public static var ping: PortalMessage { PortalMessage(.ping) }

	public init(_ kind: Kind, _ body: [String: Any]? = nil, completion: SendCallback? = nil) {
		self.kind = kind
		self.body = body
		self.createdAt = Date()
		self.completion = completion
		self.id = body?["id"] as? String ?? UUID().uuidString
	}
	
	init?(payload: [String: Any], completion: (([String: Any]) -> Void)?) {
		guard let kind = payload["kind"] as? String, let date = payload["date"] as? TimeInterval else {
			self.kind = .none
			self.body = nil
			self.completion = nil
			return nil
		}
		
		self.createdAt = Date(timeIntervalSinceReferenceDate: date)
		self.kind = Kind(rawValue: kind)
		self.body = payload["body"] as? [String: Any]
		self.id = (payload["body"] as? [String: Any])?["id"] as? String ?? UUID().uuidString
		self.completion = { result in
			if let success = try? result.get() { completion?(success) }
		}
	}
	
	public init(heartRate: Int) {
		self.init(.heartRate, ["rate": heartRate])
	}

	public var heartRate: Int? { body?["rate"] as? Int }
	var payload: [String: Any] {
		var payload: [String: Any] = ["kind": kind.rawValue, "date": createdAt.timeIntervalSinceReferenceDate]
		
		if let body = self.body {
			payload["body"] = body
		}
		
		return payload
	}
}
