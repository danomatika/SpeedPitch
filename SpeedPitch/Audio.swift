//
//  Audio.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/28/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//
// ref:
// * https://larztech.com/posts/2020/05/effects-avaudioengine/
// * https://stackoverflow.com/a/61678633

import AVKit

/// audio manager & file player
class Audio {
	let engine = AVAudioEngine()
	let player = AVAudioPlayerNode()       //< makes the sound...
	let varispeed = AVAudioUnitVarispeed() //< ...does the magic

	var isRunning: Bool {get {engine.isRunning}}
	var rate: Double {
		get {return Double(varispeed.rate)}
		set {varispeed.rate = Float(newValue)}
	}

	deinit {
		clear()
	}

	@discardableResult static func activateSession() -> Bool {
		let session = AVAudioSession.sharedInstance()
		do {
			try session.setCategory(.playback, mode: .default, options:[.mixWithOthers, .allowBluetooth])
			// playback category implies: the following options .defaultToSpeaker, .allowBluetoothA2DP, .allowAirPlay
			//try session.setCategory(.playAndRecord, mode: .default, options:[.mixWithOthers, .defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
			try session.setActive(true)
		}
		catch {
			print("Player: could not set up audio session: \(error)")
			return false
		}
		return true
	}

	static func deactivateSession() {
		let session = AVAudioSession.sharedInstance()
		do {
			try session.setActive(false)
		}
		catch {
			print("Player: could not clear audio session: \(error)")
		}
	}

	@discardableResult func setup() -> Bool {
		engine.reset()
		// FIXME: implicit node creation to avoid nil exception later on :p
		let _ = engine.outputNode
		let _ = engine.mainMixerNode
		engine.attach(player)
		engine.attach(varispeed)
		engine.connect(varispeed, to: engine.outputNode, format: nil)
		engine.connect(engine.mainMixerNode, to: varispeed, format: nil)
		return true
	}

	func clear() {
		engine.detach(player)
		engine.detach(varispeed)
	}

	@discardableResult func add(media: Media) -> Bool {
		guard let url = media.url else {return false}
		let file: AVAudioFile?
		do {
			let scoped = url.startAccessingSecurityScopedResource()
			file = try AVAudioFile(forReading: url)
			if scoped {
				url.stopAccessingSecurityScopedResource()
			}
		}
		catch {
			print("Player: could not create audio file for \(url): \(error)")
			return false
		}
		guard let buffer = AVAudioPCMBuffer(pcmFormat: file!.processingFormat, frameCapacity: AVAudioFrameCount(file!.length)) else {
			print("Player: could not create audio buffer for \(url)")
			return false
		}
		do {
			try file!.read(into: buffer)
		}
		catch {
			print("Player: could not read into audio buffer: \(error)")
			return false
		}
		engine.connect(player, to: engine.mainMixerNode, format: file!.processingFormat)
		player.scheduleBuffer(buffer, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
		engine.prepare()
		return true
	}

	func remove(media: Media) {
		engine.disconnectNodeOutput(player)
	}

	@discardableResult func start() -> Bool {
		do {
			try engine.start()
		}
		catch {
			print("Player: engine failed to start: \(error)")
			return false
		}
		return true
	}

	func pause() {
		engine.pause()
	}

	func stop() {
		engine.stop()
	}
}
