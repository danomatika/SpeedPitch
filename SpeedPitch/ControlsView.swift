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

	@IBOutlet weak var titleAndArtistLabel: UILabel!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var prevButton: UIButton!
	@IBOutlet weak var nextButton: UIButton!
	@IBOutlet weak var routePickerView: UIView!

	var player: AVPlayer? = nil
	var isPlaying: Bool = false

	override func awakeFromNib() {

		// set up audio route picker view
		self.routePickerView.addSubview(AVRoutePickerView(frame: self.routePickerView.bounds))
		self.routePickerView.backgroundColor = UIColor.clear

		prevButton.isEnabled = false
		nextButton.isEnabled = false
	}

	@IBAction func prev(_ sender: Any) {
		printDebug("ControlsView: prev")
	}

	@IBAction func next(_ sender: Any) {
		printDebug("ControlsView: next")
	}

	@IBAction func playPause(_ sender: Any) {
		printDebug("ControlsView: playPause")
		if self.isPlaying {
			self.player?.pause()
			self.isPlaying = false
		}
		else {
			self.player?.play()
			self.isPlaying = true
		}
	}
}
