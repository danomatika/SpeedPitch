//
//  ControlsView.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/22/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit
import AVKit

class ControlsView: UIView {

	@IBOutlet weak var artistAndTitleLabel: UILabel!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var prevButton: UIButton!
	@IBOutlet weak var nextButton: UIButton!
	@IBOutlet weak var loopButton: UIButton!
	@IBOutlet weak var routePickerView: UIView!

	weak var playerViewController: PlayerViewController?

	override func awakeFromNib() {
		artistAndTitleLabel.text = "" // empty on start

		// set up audio route picker view
		routePickerView.addSubview(AVRoutePickerView(frame: routePickerView.bounds))
		routePickerView.backgroundColor = UIColor.clear

		update()
	}

	@IBAction func prev(_ sender: Any) {
		printDebug("ControlsView: prev")
		if let playerViewController = playerViewController {
			let wasPlaying = playerViewController.player.isPlaying
			playerViewController.stop()
			if playerViewController.prev() && wasPlaying {
				playerViewController.play()
			}
		}
	}

	@IBAction func next(_ sender: Any) {
		printDebug("ControlsView: next")
		if let playerViewController = playerViewController {
			let wasPlaying = playerViewController.player.isPlaying
			playerViewController.stop()
			if playerViewController.next() && wasPlaying {
				playerViewController.play()
			}
		}
	}

	@IBAction func playPause(_ sender: Any) {
		printDebug("ControlsView: playPause")
		playerViewController?.togglePlay()
	}

	// make sure player loop state is also updated
	@IBAction func loop(_ sender: Any) {
		guard let file = playerViewController?.playlist.current else {return}
		file.loop = !file.loop
		loopButton.tintColor = (file.loop ? self.tintColor : .systemGray)
		if let player = playerViewController?.player {
			player.isLooping = file.loop
		}
	}

	func update() {

		// label
		if let player = playerViewController?.player {
			if player.isOpen {
				artistAndTitleLabel.text = playerViewController?.playlist.current?.description ?? ""
			}
			else {
				artistAndTitleLabel.text = ""
			}
		}

		// play/pause button
		playPauseButton.isEnabled = !(playerViewController?.playlist.isEmpty ?? true)
		let playing = playerViewController?.player.isPlaying ?? false
		var name = "play.fill"
		if playing {
			name = "pause.fill"
		}
		var image: UIImage?
		if #available(iOS 13.0, *) {
			image = UIImage(systemName: name)
		}
		else {
			// use fallback icon
			image = UIImage(named: name)
		}
		if image != nil {
			playPauseButton.setImage(image, for: .normal)
		}

		// prev/next buttons
		if let playlist = playerViewController?.playlist {
			prevButton.isEnabled = (!playlist.isEmpty && !playlist.isFirst) || playlist.isLooping
			nextButton.isEnabled = (!playlist.isEmpty && !playlist.isLast) || playlist.isLooping
		}
		else {
			prevButton.isEnabled = false
			nextButton.isEnabled = false
		}

		// loop button
		if let file = playerViewController?.playlist.current {
			loopButton.isEnabled = true
			loopButton.tintColor = (file.loop ? self.tintColor : .systemGray)
		}
		else {
			loopButton.isEnabled = false
		}
	}

}
