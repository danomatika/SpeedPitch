//
//  Util.swift
//  ZirkVideoPlayer
//
//  Created by Dan Wilcox on 6/20/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import Foundation

// MARK: Global Helpers

/// print that is ignored in release builds
func printDebug(_ msg: String) {
#if DEBUG
	print(msg)
#endif
}

// MARK: Class Extensions

extension URL {

	/// app Documents url getter
	static var documents: URL {
		return FileManager
			.default
			.urls(for: .documentDirectory, in: .userDomainMask)[0]
	}
}

extension Comparable {

	/// clamp to range: number.clamped(to: 0...10)
	func clamped(to limits: ClosedRange<Self>) -> Self {
		return min(max(self, limits.lowerBound), limits.upperBound)
	}
}

extension Double {

	/// map from range to new range linearly:
	/// number.mapped(from: 0...100, to: 0...1)
	func mapped(from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
		if(abs(from.lowerBound - from.upperBound) < Double.ulpOfOne) {
			return to.lowerBound
		}
		return ((self - from.lowerBound) / (from.upperBound - from.lowerBound) *
					(to.upperBound - to.lowerBound) + to.lowerBound)
	}

	/// map from range to new range along a sin curve 0 - pi/4:
	/// number.mapped(from: 0...100, to: 0...1)
	func mappedSin(from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
		if(abs(from.lowerBound - from.upperBound) < Double.ulpOfOne) {
			return to.lowerBound
		}
		return (sin((self - from.lowerBound) / (from.upperBound - from.lowerBound) * Double.pi * 0.25) *
					(to.upperBound - to.lowerBound) + to.lowerBound)
	}

	/// linear interpolation between from & to, t is normalized pos in range 0.0 - 1.0
	static func lerp(from: Double, to: Double, t: Double) -> Double {
		return from + (to - from) * t
	}

	/// moving average
	static func mavg(old: Double, new: Double, windowSize: UInt) -> Double {
		return old * ((Double(windowSize) - 1.0) / Double(windowSize)) + new * (1.0 / Double(windowSize))
	}
}
