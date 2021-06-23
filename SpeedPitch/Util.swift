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

extension Comparable {

	/// clamp to range: number.clamped(to: 0...10)
	func clamped(to limits: ClosedRange<Self>) -> Self {
		return min(max(self, limits.lowerBound), limits.upperBound)
	}
}

extension Double {

	/// map from range to new range: number.mapped(from: 0...100, to: 0...1)
	func mapped(from: ClosedRange<Double>, to: ClosedRange<Double>) -> Double {
		if(abs(from.lowerBound - from.upperBound) < Double.ulpOfOne) {
			return to.lowerBound
		}
		return ((self - from.lowerBound) / (from.upperBound - from.lowerBound) *
					(to.upperBound - to.lowerBound) + to.lowerBound)
	}

}
