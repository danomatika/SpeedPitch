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
	func clockDidTick(_ clock: Clock, time: TimeInterval, delta: TimeInterval)
	func clockStarted(_ clock: Clock)
	func clockStopped(_ clock: Clock)
}

/// repeating timer events
/// ref: https://stackoverflow.com/a/43746977
class Clock {
	static let defaultGrain = 0.002
	var delegate: ClockDelegate?

	private var timer: DispatchSourceTimer!
	private var timestamp: TimeInterval = 0

	fileprivate var _isRunning = false
	var isRunning: Bool {
		get {return _isRunning}
		set {}
	}

	deinit {
		stop()
	}

	func start() {
		if _isRunning {return}
		let queue = DispatchQueue(label: "com.danomatika.SpeedPitch.clock", qos: .userInteractive)
		timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
		timer.schedule(deadline: .now(), repeating: Clock.defaultGrain, leeway: .milliseconds(2))
		timer.setEventHandler {
			let then = self.timestamp
			let now = NSDate().timeIntervalSince1970
			self.timestamp = now
			self.tick(now, delta: now - then)
		}
		timer.resume()
		started()
	}

	func stop() {
		if !_isRunning {return}
		timer.suspend()
		timer = nil
		_isRunning = false
		stopped()
	}

	/// returns current time in seconds
	static func now() -> TimeInterval {
		return NSDate().timeIntervalSince1970
	}

	// MARK: Subclass

	func started() {
		self.delegate?.clockStarted(self)
	}

	func stopped() {
		self.delegate?.clockStopped(self)
	}

	func tick(_ time: TimeInterval, delta: TimeInterval) {
		self.delegate?.clockDidTick(self, time: time, delta: delta)
	}
}
