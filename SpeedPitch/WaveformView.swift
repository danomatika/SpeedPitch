//
//  WaveformView.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 7/18/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//
// ref:
// * https://www.raywenderlich.com/21672160-avaudioengine-tutorial-for-ios-getting-started
// * https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks

import UIKit
import AVKit

/// mono channel waveform view
class WaveformView : UIView {

	let bufferSize: AVAudioFrameCount = 1024 //< desired tap buffer size

	var node: AVAudioNode? //< tapped node
	var samples: [Float] = [] //< current sample buffer
	var isTapped: Bool {return node != nil} //< tapped?

	/// tap into a node's output
	func tap(node: AVAudioNode) {
		if isTapped {return}
		let format = node.outputFormat(forBus: 0)
		node.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, _ in
			// pass sample buffer to UI thread if not all zeros
			guard let channelData = buffer.floatChannelData else {return}
			let samples = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map {
				channelData.pointee[$0]
			}
			let isZeroAvg = (samples.reduce(0, +) / Float(buffer.frameLength) == 0)
			DispatchQueue.main.async {
				self.samples = (isZeroAvg ? [] : samples)
				self.setNeedsDisplay()
			}
		}
		self.node = node
	}

	/// stop the tap
	func untap() {
		if !isTapped {return}
		node?.removeTap(onBus: 0)
		node = nil
		samples = []
		setNeedsDisplay()
	}

	override func draw(_ rect: CGRect) {
		if samples.isEmpty {return}
		guard let context = UIGraphicsGetCurrentContext() else {return}

		// average chunks of samples for each horz pixel
		let chunkSize = Int(CGFloat(samples.count) / CGFloat(rect.size.width))
		if chunkSize <= 0 {return}
		let chunked = stride(from: 0, to: samples.count, by: chunkSize).map {
			Array(samples[$0 ..< Swift.min($0 + chunkSize, samples.count)])
		}
		let averaged = stride(from: 0, to: Int(chunked.count), by: 1).map {
			chunked[$0].reduce(0, +) / Float(chunked[$0].count)
		}

		// draw averaged sample values at +/- half height
		let halfh = CGFloat(rect.size.height / 2)
		context.move(to: CGPoint(x: 0, y: halfh + CGFloat(averaged[0]) * halfh))
		for x in 0..<averaged.count {
			context.addLine(to: CGPoint(x: CGFloat(x), y: halfh + CGFloat(averaged[x]) * halfh))
		}
		context.setStrokeColor(UIColor.systemGray.cgColor)
		context.strokePath()
	}

}
