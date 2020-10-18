//
//  PortalMessage.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation

public typealias SendCallback = (Result<[String: Any], Error>) -> Void

public struct PortalMessage: CustomStringConvertible {
	public struct Kind: Equatable {
		public let rawValue: String
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		public static let none = Kind(rawValue: "_none")
		public static let ping = Kind(rawValue: "_ping")
		public static let string = Kind(rawValue: "_string")
		
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
	
	public init(_ kind: Kind, _ body: [String: Any]? = nil, completion: SendCallback? = nil) {
		self.kind = kind
		self.body = body
		self.completion = completion
	}
	
	init?(payload: [String: Any], completion: (([String: Any]) -> Void)?) {
		guard let kind = payload["kind"] as? String else {
			self.kind = .none
			self.body = nil
			self.completion = nil
			return nil
		}
		
		self.kind = Kind(rawValue: kind)
		self.body = payload["body"] as? [String: Any]
		self.completion = { result in
			if let success = try? result.get() { completion?(success) }
		}
	}
	
	var payload: [String: Any] {
		var payload: [String: Any] = ["kind": kind.rawValue]
		
		if let body = self.body {
			payload["body"] = body
		}
		
		return payload
	}
}
