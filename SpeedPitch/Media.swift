//
//  Media.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/23/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import AVKit
import MediaPlayer

/// media event delegate
protocol MediaDelegate {
	func mediaDidStartPlaying(_ media: Media)
	func mediaDidPausePlaying(_ media: Media)
	func mediaDidFinishPlaying(_ media: Media)
}

/// media item base class
class Media: NSObject {

	var title: String = "unknown"
	var artist: String = "unknown"
	var url: URL?
	var image: UIImage?
	var meta: [String: AnyObject] = [:]

	var isPlaying: Bool = false
	var rate: Double = 1.0
	var loop: Bool = false

	var delegate: MediaDelegate?

	func play() {}

	func pause() {}

	func toggle() {}

	func rewind() {}

	func setRate(_ rate: Double) {}
}

/// single song file media
class SongMedia : Media, AVAudioPlayerDelegate {

	var player: AVPlayer? = nil

	override var isPlaying: Bool { get { return _isPlaying } set {}}
	private var _isPlaying: Bool = false

	init?(url: URL) {
		super.init()
		if !self.open(url: url) {return nil}
		self.readMetadata()
		self.setupObservers()
	}

	init?(url: URL, title: String, artist: String) {
		super.init()
		if !self.open(url: url) {return nil}
		self.title = title
		self.artist = artist
		self.setupObservers()
	}

	init?(mediaItem: MPMediaItem) {
		super.init()
		guard let url = mediaItem.value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {return nil}
		if !self.open(url: url) {return nil}
		if let title = mediaItem.value(forProperty: MPMediaItemPropertyTitle) as? String {
			self.title = title
		}
		if let artist = mediaItem.value(forProperty: MPMediaItemPropertyArtist) as? String {
			self.artist = artist
		}
		self.setupObservers()
	}

	deinit {
		self.clearObservers()
	}

	override func play() {
		self.player?.play()
	}

	override func pause() {
		self.player?.pause()
	}

	override func toggle() {
		if self.isPlaying {
			self.player?.pause()
		}
		else {
			self.player?.play()
		}
	}

	override func rewind() {
		self.player?.seek(to: CMTime.zero)
	}

	override func setRate(_ rate: Double) {
		self.player?.rate = Float(rate)
	}

	// MARK: Notifications and KVO

	private var rateObserver: NSKeyValueObservation?
	private var endObserver: Any?

	private func setupObservers() {
		self.rateObserver = self.player?.observe(\.rate,
												 options: [.new, .old],
												 changeHandler: { (player, change) in
			 if player.rate == 0  {
				self._isPlaying = false
				self.delegate?.mediaDidPausePlaying(self)
			}
			else {
				let wasPlaying = self._isPlaying
				self._isPlaying = true
				if !wasPlaying  {
					self.delegate?.mediaDidStartPlaying(self)
				}
			}
		 })
		setupEndObserver()
	}

	private func clearObservers() {
		self.rateObserver?.invalidate()
		self.rateObserver = nil
		if let observer = endObserver {
			self.player?.removeTimeObserver(observer)
			endObserver = nil
		}
	}

	private func setupEndObserver() {
		guard let player = self.player else { return }
		guard let duration = player.currentItem?.duration, duration.value != 0 else {
			// wait a moment in for buffer, etc
			// TODO: replace this with observing readyToPlay status
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
				self?.setupEndObserver()
			})
			return
		}
		let endTime = NSValue(time: duration - CMTimeMakeWithSeconds(0.1, preferredTimescale: duration.timescale))
		endObserver = player.addBoundaryTimeObserver(forTimes: [endTime], queue: .main, using: {
			if self.loop {
				self.rewind()
				self.play()
			}
			else {
				self.player?.pause()
				self.delegate?.mediaDidFinishPlaying(self)
			}
		})
	}

	// MARK: Private

	private func open(url: URL) -> Bool {
		let playerItem = AVPlayerItem(url: url)
		if playerItem.status == .failed {return false}
		self.player	= AVPlayer(playerItem: playerItem)
		if player?.status == .failed {return false}
		self.url = url
		self.player?.currentItem?.audioTimePitchAlgorithm = .varispeed
		return true
	}

	private func readMetadata() {
		if let metadata = self.player?.currentItem?.asset.commonMetadata {
			metadata.forEach { item in
				if(item.commonKey == AVMetadataKey.commonKeyTitle) {
					if let title = item.value as? String {
						self.title = title
					}
				}
				else if(item.commonKey == AVMetadataKey.commonKeyArtist) {
					if let artist = item.value as? String {
						self.title = artist
					}
				}
			}
		}
	}

}

/// multi-file project media
class ProjectMedia : Media {

	var players: [AVPlayer] = []
}
