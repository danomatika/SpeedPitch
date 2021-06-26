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

	var start: TimeInterval {    //< start timestamp in seconds
		get {return _start}
	}
	var end: TimeInterval {      //< (future) end timestamp in seconds
		get {return _end}
	}
	var duration: TimeInterval { //< event duration in seconds
		get {return end - start}
	}
	var isActive: Bool = false   //< is the event currently active?
	var scheduler: Scheduler?    //< parent scheduler

	fileprivate var _start: TimeInterval = 0
	fileprivate var _end: TimeInterval = 0

	/// set start time and event duration
	func setTime(start: TimeInterval, duration: TimeInterval) {
		_start = start
		_end = start + duration
	}

	/// set start time as now and event duration
	func setTimeNow(duration: TimeInterval) {
		setTime(start: Clock.now(), duration: duration)
	}

	/// set start time as now + after in the future and event duration
	func setTime(after: TimeInterval, duration: TimeInterval) {
		setTime(start: Clock.now() + after, duration: duration)
	}

	// MARK: Subclassing

	/// event start at time in seconds
	func started(_ time: TimeInterval) {}

	/// event stop at time in seconds
	func stopped(_ time: TimeInterval) {}

	/// event clock tick in seconds with delta since last tick
	func tick(_ time: TimeInterval, delta: TimeInterval) {}
}

/// tick-based event scheduler
class Scheduler: Clock {
	var events: [ScheduledEvent] = []            //< current events
	private var newEvents: [ScheduledEvent] = [] //< new events to be activated

	/// add event, new events are activated on the next clock tick
	/// ignores events which have already been added
	func add(event: ScheduledEvent) {
		if events.contains(where: {$0 === event}) {return}
		events.append(event)
		event.scheduler = self
	}

	/// remove event
	func remove(event: ScheduledEvent) {
		if event.isActive {
			event.isActive = false
		}
		events.removeAll(where: {$0 === event})
		event.scheduler = nil
	}

	/// shared instance
	static let shared = Scheduler()

	// MARK: Clock

	/// reactivate events
	override func started() {
		for event in self.events {
			if event.start <= time {
				event.isActive = true
			}
		}
	}

	/// deactivate events
	override func stopped() {
		for event in self.events {
			event.isActive = false
		}
	}

	/// (de)activate events based on start & end times
	override func tick(_ time: TimeInterval, delta: TimeInterval) {
		if events.isEmpty {return} // nothing to do
		DispatchQueue.main.async {
			var active: [ScheduledEvent] = []
			for event in self.events {
				if !event.isActive && event.start <= time {
					event.isActive = true
					event.started(time)
				}
				if !event.isActive {continue}
				event.tick(time, delta: delta)
				if event.end <= time {
					event.isActive = false
					event.stopped(time)
					event.scheduler = nil
				}
				if event.isActive {active.append(event)}
			}
			self.events = active
		}
	}

}
