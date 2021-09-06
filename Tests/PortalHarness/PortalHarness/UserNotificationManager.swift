//
//  UserNotificationManager.swift
//  PortalHarness_Phone
//
//  Created by Ben Gottlieb on 1/4/21.
//

import Foundation
import UserNotifications

public class UserNotificationManager: NSObject, UNUserNotificationCenterDelegate {
	public static let instance = UserNotificationManager()

	public func notify(title: String, body: String, in interval: TimeInterval) {
		let content = UNMutableNotificationContent()
		
		content.title = title
		content.body = body
		content.sound = UNNotificationSound.default
		
		
		logg("Queuing “\(title)” in \(interval) seconds")
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
		
		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
		UNUserNotificationCenter.current().add(request) { err in
			if let error = err { logg("Error when adding a notification: \(error)") }
		}
	}
	
	public func notify(title: String, body: String, when: Date) {
		let interval = abs(when.timeIntervalSinceNow)
		notify(title: title, body: body, in: interval)
	}
	
	func setup() {
		UNUserNotificationCenter.current().delegate = self
		
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
			 guard granted else { return }
			 DispatchQueue.main.async {
			 }
		}

	}
	
	public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		
	}
	
	public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		
	}
	
	public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
		
	}

}
