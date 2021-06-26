//
//  Line.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/25/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import Foundation

/// linear ramp with interpolation, based on the [line] object in Pure Data
class Line: ScheduledEvent {
	var startValue: Double = 0
	var endValue: Double = 0
	var startTime: TimeInterval = 0
	var duration: TimeInterval = 0
	var handler: ((Double)->Void)?

	var value: Double = 0 //< current value

	fileprivate var _isRunning = false
	var isRunning: Bool {
		get {return _isRunning}
		set {}
	}

	override init() {
		super.init()
	}

	init(value: Double) {
		super.init()
		set(value)
	}

	deinit {
		stop()
	}

	func set(_ value: Double) {
		stop()
		startValue = value
		endValue = value
		self.value = value
	}

	func set(_ target: Double, duration: TimeInterval, handler: @escaping ((Double)->Void)) {
		startTime = Clock.now()
		self.endValue = target
		self.duration = duration
		self.handler = handler
		self.startValue = value
		handler(value)
		if !_isRunning {
			Scheduler.shared.add(event: self)
			_isRunning = true
		}
	}

	func set(_ value: Double, target: Double, duration: TimeInterval, handler: @escaping ((Double)->Void)) {
		startTime = Clock.now()
		startValue = value
		endValue = target
		self.duration = duration
		self.handler = handler
		self.value = value
		handler(value)
		if !_isRunning {
			Scheduler.shared.add(event: self)
			_isRunning = true
		}
	}

	func stop() {
		if _isRunning {
			Scheduler.shared.remove(event: self)
			_isRunning = false
		}
		handler = nil
	}

	// MARK: ScheduledEvent

	override func tick(_ time: TimeInterval, delta: TimeInterval) -> Bool {
		var t = (time - startTime) / duration
		if t >= 1 {
			_isRunning = false
		}
		t = t.clamped(to: 0...1)
		let v = Double.lerp(from: startValue, to: endValue, t: t)
		if v != value {
			value = v
			handler?(value)
		}
		if !_isRunning {
			handler = nil
		}
		return !_isRunning
	}

}
