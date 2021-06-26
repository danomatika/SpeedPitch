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

	var value: Double {            //< current value
		get {return _value}
	}
	var startValue: Double = 0     //< value at event start
	var endValue: Double = 0       //< value at event end
	var handler: ((Double)->Void)? //< interpolation handler

	fileprivate var _value: Double = 0

	init(_ value: Double) {
		super.init()
		set(value)
	}

	deinit {
		stop()
	}

	/// set value, stops interpolation
	func set(_ value: Double) {
		stop()
		startValue = value
		endValue = value
		_value = value
	}

	/// set target for interpolation (current) value -> target,
	/// starts interpolation which calls handler every clock tick:
	/// line.set(target: 1, duration: 0.5) { value in
	///      // do something with value
	/// }
	func set(target: Double, duration: TimeInterval,
			 handler: @escaping ((Double)->Void)) {
		setTimeNow(duration: duration)
		startValue = value
		endValue = target
		self.handler = handler
		handler(value)
		if !(scheduler != nil) {
			Scheduler.shared.add(event: self)
		}
	}

	/// set value and target for interpolation value -> target,
	/// starts interpolation which calls handler every clock tick:
	/// line.set(0, target: 1, duration: 0.5) { value in
	///      // do something with value
	/// }
	func set(_ value: Double, target: Double, duration: TimeInterval,
			 handler: @escaping ((Double)->Void)) {
		setTimeNow(duration: duration)
		startValue = value
		endValue = target
		_value = value
		self.handler = handler
		handler(value)
		if !(scheduler != nil) {
			Scheduler.shared.add(event: self)
		}
	}

	/// stops interpolation
	func stop() {
		if !(scheduler != nil) {
			Scheduler.shared.remove(event: self)
		}
		handler = nil
	}

	// MARK: ScheduledEvent

	/// lerp...
	override func tick(_ time: TimeInterval, delta: TimeInterval) {
		let t = ((time - start) / duration).clamped(to: 0...1)
		_value = Double.lerp(from: startValue, to: endValue, t: t)
		handler?(_value)
	}

}
