//
//  PortalMessage.swift
//  PortalHarness
//
//  Created by Ben Gottlieb on 10/17/20.
//

import Foundation

public typealias SendCallback = (Result<[String: Any], Error>) -> Void

public struct PortalMessage: CustomStringConvertible {
	public struct Kind {
		public let rawValue: String
		public init(rawValue: String) {
			self.rawValue = rawValue
		}
		
		public static let none = Kind(rawValue: "_none")
		public static let ping = Kind(rawValue: "_ping")
	}
	
	public var description: String { "\(kind.rawValue): \(body ?? [:])" }
	
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
