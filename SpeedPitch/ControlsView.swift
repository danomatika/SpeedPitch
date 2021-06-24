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
	@IBOutlet weak var routePickerView: UIView!

	weak var player: Media? {
		didSet {
			if player != nil {
				playPauseButton.isEnabled = true
				artistAndTitleLabel.text = player?.description
			}
			else {
				playPauseButton.isEnabled = false
				artistAndTitleLabel.text = ""
			}
		}
	}

	override func awakeFromNib() {
		artistAndTitleLabel.text = "" // empty on start

		// set up audio route picker view
		self.routePickerView.addSubview(AVRoutePickerView(frame: self.routePickerView.bounds))
		self.routePickerView.backgroundColor = UIColor.clear

		self.prevButton.isEnabled = false
		self.nextButton.isEnabled = false
		self.playPauseButton.isEnabled = false
	}

	@IBAction func prev(_ sender: Any) {
		printDebug("ControlsView: prev")
	}

	@IBAction func next(_ sender: Any) {
		printDebug("ControlsView: next")
	}

	@IBAction func playPause(_ sender: Any) {
		printDebug("ControlsView: playPause")
		self.player?.toggle()
	}

	func update() {
		// play/pause button
		let playing = self.player?.isPlaying ?? false
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
			self.playPauseButton.setImage(image, for: .normal)
		}
	}
}
