//
//  Clock.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/25/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import Foundation

/// clock event delegate
protocol ClockDelegate {
	func clockStarted(_ clock: Clock)
	func clockStopped(_ clock: Clock)
	func clockDidTick(_ clock: Clock, time: TimeInterval, delta: TimeInterval)
}

/// repeating timer events
/// ref: https://stackoverflow.com/a/43746977
class Clock {

	var delegate: ClockDelegate? //< event delegate
	var time: TimeInterval {     //< current time
		get {return _time}
	}
	var isRunning: Bool {        //< is the clock running?
		get {return _isRunning}
		set {}
	}

	static let queueLabel = "com.danomatika.SpeedPitch.clock"
	static let defaultGrain = 0.002 //< 20 ms tick duration

	fileprivate var _timer: DispatchSourceTimer! //< source timer
	fileprivate var _time: TimeInterval = 0 //< last tick timestamp
	fileprivate var _isRunning = false

	deinit {
		stop()
	}

	/// start the clock
	func start() {
		if _isRunning {return}
		let queue = DispatchQueue(label: Clock.queueLabel,
								  qos: .userInteractive)
		_timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
		_timer.schedule(deadline: .now(), repeating: Clock.defaultGrain,
						leeway: .milliseconds(2))
		_timer.setEventHandler {
			let then = self._time
			let now = NSDate().timeIntervalSince1970
			self._time = now
			self.tick(now, delta: now - then)
		}
		_timer.resume()
		started()
	}

	/// stop the clock
	func stop() {
		if !_isRunning {return}
		_timer.suspend()
		_timer = nil
		_isRunning = false
		stopped()
	}

	/// returns current time in seconds
	static func now() -> TimeInterval {
		return NSDate().timeIntervalSince1970
	}

	// MARK: Subclass

	/// clock has started
	func started() {
		delegate?.clockStarted(self)
	}

	/// lock has stopped
	func stopped() {
		delegate?.clockStopped(self)
	}

	/// clock has ticked
	func tick(_ time: TimeInterval, delta: TimeInterval) {
		delegate?.clockDidTick(self, time: time, delta: delta)
	}

}
