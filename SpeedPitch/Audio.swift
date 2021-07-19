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

extension AVAudioFile {

	var duration: TimeInterval {
		return Double(length) / Double(processingFormat.sampleRate)
	}

}

extension AVAudioPlayerNode {

	var currentTime: TimeInterval {
		if let nodeTime = lastRenderTime,
		   let playerTime = playerTime(forNodeTime: nodeTime) {
			return Double(playerTime.sampleTime) / playerTime.sampleRate
		}
		return 0
	}

}

/// audio file with meta data
class AudioFile {

	var url: URL!
	var title: String = "unknown"
	var artist: String = "unknown"
	var duration: Double = 0 //< duration in seconds
	var image: UIImage?      //< optional thumbnail

	init?(url: URL) {
		self.url = url
		let scoped = url.startAccessingSecurityScopedResource()
		let asset = AVAsset(url: url)
		if scoped {url.stopAccessingSecurityScopedResource()}
		if !asset.isPlayable {return nil}
		duration = asset.duration.seconds
		for item in asset.commonMetadata {
			if(item.commonKey == AVMetadataKey.commonKeyTitle) {
				if let t = item.value as? String {
					title = t
				}
			}
			else if(item.commonKey == AVMetadataKey.commonKeyArtist) {
				if let a = item.value as? String {
					artist = a
				}
			}
		}
	}

	var description: String {
		get {
			if artist == "unknown" && title == "unknown" && url.isFileURL {
				// show filename if no metadata
				return url.lastPathComponent
			}
			else {
				return "\(artist) - \(title)"
			}
		}
		set {}
	}
}

/// player event delegate
protocol AudioPlayerDelegate {
	func playerDidStartPlaying(_ player: AudioPlayer)
	func playerDidPausePlaying(_ player: AudioPlayer)
	func playerDidFinishPlaying(_ player: AudioPlayer)
}

// audio file player
class AudioPlayer {

	let player = AVAudioPlayerNode() //< makes the sound...
	private var buffer: AVAudioPCMBuffer? //< sample buffer

	var delegate: AudioPlayerDelegate?
	var isOpen: Bool { //< is the audio file open?
		// don't use player.isPlaying which becomes false after a route change
		get {return (buffer != nil)}
	}
	var isPlaying: Bool { //< is the audio file playing?
		get {return _isPlaying}
	}
	var isLooping: Bool { //< is playback looping?
		get {return _isLooping}
		set {
			if newValue == _isLooping {return}
			_isLooping = newValue
			if isPlaying {
				play() // replay to set loop option
			}
		}
	}

	fileprivate var _isPlaying = false
	fileprivate var _isLooping = false
	fileprivate var _ignoreFinish = false

	deinit {
		stop()
		close()
	}

	@discardableResult func open(file: AudioFile) -> Bool {
		return open(url: file.url)
	}

	@discardableResult func open(url: URL) -> Bool {
		stop()
		close()
		let file: AVAudioFile?
		do {
			let scoped = url.startAccessingSecurityScopedResource()
			file = try AVAudioFile(forReading: url)
			if scoped {
				url.stopAccessingSecurityScopedResource()
			}
		}
		catch {
			print("AudioPlayer: could not create audio file for \(url): \(error)")
			return false
		}
		guard let buffer = AVAudioPCMBuffer(pcmFormat: file!.processingFormat,
											frameCapacity: AVAudioFrameCount(file!.length)) else {
			print("AudioPlayer: could not create audio buffer for \(url)")
			return false
		}
		do {
			try file!.read(into: buffer)
			self.buffer = buffer
		}
		catch {
			print("AudioPlayer: could not read into audio buffer: \(error)")
			return false
		}
		if let engine = (player.engine ?? nil) {
			engine.connect(player, to: engine.mainMixerNode, format: file!.processingFormat)
			engine.prepare()
		}
		else {
			print("AudioPlayer: not attached to audio engine")
			return false
		}
		return true
	}

	func close() {
		player.engine?.disconnectNodeOutput(player)
		buffer = nil
		_isPlaying = false
		_ignoreFinish = false
	}

	func play() {
		if buffer != nil {
			var options: AVAudioPlayerNodeBufferOptions = []
			if isLooping {
				options = [.loops]
			}
			player.scheduleBuffer(buffer!, at: nil,
								options: options,
								completionCallbackType: .dataPlayedBack) { type in
				// ignore finish event if triggered manually, ie. via stop()
				if let engine = self.player.engine,
				   engine.isRunning && !self._ignoreFinish {
					printDebug("AudioPlayer: finished")
					self.delegate?.playerDidFinishPlaying(self)
				}
			}
			player.play()
			player.engine?.prepare()
			_ignoreFinish = false
			let wasPlaying = _isPlaying
			_isPlaying = true
			if !wasPlaying {
				delegate?.playerDidStartPlaying(self)
			}
		}
	}

	func pause() {
		if buffer != nil {
			player.pause()
			_ignoreFinish = true
		}
		let wasPlaying = _isPlaying
		_isPlaying = false
		if wasPlaying {
			delegate?.playerDidPausePlaying(self)
		}
	}

	func stop() {
		if buffer != nil && _isPlaying {
			_ignoreFinish = true
			player.stop()
			_ignoreFinish = false
		}
		_isPlaying = false
	}

	func toggle() {
		if _isPlaying {
			pause()
		}
		else {
			play()
		}
	}

	// ref: https://stackoverflow.com/questions/29954206/avaudioengine-seek-the-time-of-the-song
//	func seek(to time: TimeInterval) {
//		if buffer != nil {
//			guard let renderTime = player.lastRenderTime else {return}
//			guard let playerTime = player.playerTime(forNodeTime: renderTime) else {return}
//			let newsampletime = AVAudioFramePosition(playerTime.sampleRate * time)
//			//var length = Float(songDuration!) - time
//			//var framestoplay = AVAudioFrameCount(Float(playerTime.sampleRate) * length)
//			player.stop()
//			player.scheduleSegment(file!, startingFrame: newsampletime, frameCount: 0, at: nil, completionHandler: nil)
//			player.play()
//		}
//	}

}

/// audio manager
/// graph: player(s) -> mixer -> varispeed -> output
class AudioEngine {

	let engine = AVAudioEngine()
	let varispeed = AVAudioUnitVarispeed() //< ...does the magic
	var players: [AudioPlayer] = [] //< attached players

	var isRunning: Bool {get {engine.isRunning}} //< is the engine running?
	var rate: Double { //< playback rate: 0.25 - 4.0 (AVAudioUnitVarispeed docs)
		get {return Double(varispeed.rate)}
		set {varispeed.rate = Float(newValue)}
	}

	init() {
		setupObservers()
	}

	deinit {
		clearObservers()
	}

	@discardableResult static func activateSession() -> Bool {
		let session = AVAudioSession.sharedInstance()
		do {
			// playback category implies: .defaultToSpeaker, .allowBluetoothA2DP, .allowAirPlay
			try session.setCategory(.playback, mode: .default, options:[])
			try session.setActive(true)
		}
		catch {
			print("AudioEngine: could not set up audio session: \(error)")
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
			print("AudioEngine: could not clear audio session: \(error)")
		}
	}

	func setup() {
		// implicit node creation to avoid nil exception later on :p
		let output = engine.outputNode
		let mixer = engine.mainMixerNode
		engine.attach(varispeed)
		engine.connect(varispeed, to: output, format: nil)
		engine.connect(mixer, to: varispeed, format: nil)
	}

	func attach(player: AudioPlayer) {
		if players.contains(where: {$0 === player}) {return}
		engine.attach(player.player)
		players.append(player)
	}

	func dettach(player: AudioPlayer) {
		engine.detach(player.player)
		players.removeAll(where: {$0 === player})
	}

	@discardableResult func start() -> Bool {
		if engine.isRunning {return true}
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

	// MARK: Notifications

	func setupObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationChange),
											   name: .AVAudioEngineConfigurationChange, object: nil)
	}

	func clearObservers() {
		NotificationCenter.default.removeObserver(self, name: .AVAudioEngineConfigurationChange, object: nil)
	}

	/// restart audio engine and players after a route change
	@objc func handleConfigurationChange(_ notification: Notification) {
		printDebug("AudioEngine: route change, restarting")
		stop()
		start()
		for player: AudioPlayer in players {
			engine.disconnectNodeOutput(player.player)
			engine.connect(player.player, to: engine.mainMixerNode, format: nil)
			if player.isPlaying {
				player.play()
			}
		}
	}
}
