//
//  Scheduler.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/25/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import Foundation

/// scheduler event baseclass, do not use directly
class ScheduledEvent {

	/// event start at time in seconds
	func started(_ time: TimeInterval) {}

	/// event stop at time in seconds
	func stopped(_ time: TimeInterval) {}

	/// event clock tick in seconds with delta since last tick
	/// returns true when event is finished
	func tick(_ time: TimeInterval, delta: TimeInterval) -> Bool {return true}
}

/// tick-based event scheduler
class Scheduler: Clock {
	var events: [ScheduledEvent] = []
	var newEvents: [ScheduledEvent] = []

	func add(event: ScheduledEvent) {
		if events.contains(where: {$0 === event}) {return}
		if newEvents.contains(where: {$0 === event}) {return}
		newEvents.append(event)
	}

	func remove(event: ScheduledEvent) {
		events.removeAll(where: {$0 === event})
		newEvents.removeAll(where: {$0 === event})
	}

	/// shared instance
	static let shared = Scheduler()

	// MARK: Clock

	override func started() {}

	override func stopped() {}

	override func tick(_ time: TimeInterval, delta: TimeInterval) {
		if events.isEmpty && newEvents.isEmpty {return}
		DispatchQueue.main.async {
			var active: [ScheduledEvent] = []
			for event in self.events {
				if !event.tick(time, delta: delta) {
					active.append(event)
				}
			}
			for event in self.newEvents {
				active.append(event)
			}
			self.newEvents = []
			self.events = active
		}
	}

}
