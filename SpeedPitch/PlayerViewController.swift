//
//  PlayerViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController, PickerDelegate, MediaDelegate, LocationDelegate {

	@IBOutlet weak var dashboardView: DashboardView!
	@IBOutlet weak var controlsView: ControlsView!

	var player: SongMedia? = nil
	let picker = Picker()
	let location = Location()

	var rate: Double = 2 // current playback rate
	let line = Line(value: 0.05)

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		picker.delegate = self
		location.delegate = self
		location.enable()

		// keep screen awake
		UIApplication.shared.isIdleTimerDisabled = true

		// start background clock
		Scheduler.shared.start()
	}

	// toggle nav & controls visibility
	func toggleControlVisibility() {
		if let navBar = self.navigationController?.navigationBar {
			self.navigationController?.setNavigationBarHidden(!navBar.isHidden, animated: true)
		}
		UIView.transition(with: self.controlsView,
						  duration: TimeInterval(UINavigationController.hideShowBarDuration),
						  options: .transitionCrossDissolve,
						  animations: {
			self.controlsView.isHidden = !self.controlsView.isHidden
		})
	}

	// MARK: Actions

	/// show media picker
	@IBAction func selectMedia(_ sender: Any) {
		printDebug("PlayerViewController: selectMedia")
		picker.presentMediaPickerFrom(controller: self, sender: sender)
	}

	/// show documents picker
	@IBAction func selectDocuments(_ sender: Any) {
		printDebug("PlayerViewController: selectDocuments")
		picker.presentDocumentPickerFrom(controller: self, sender: sender)
	}

	/// show more actions
	@IBAction func showMoreActions(_ sender: Any) {
		printDebug("PlayerViewController: showMoreActions")
		let alert = UIAlertController()
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
			alert.dismiss(animated: true, completion: nil)
		})
		let infoAction = UIAlertAction(title: "Info", style: .default, handler: { action in
			printDebug("show info")
			alert.dismiss(animated: true, completion: nil)
			self.performSegue(withIdentifier: "ShowInfo", sender: self)
		})
		let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { action in
			printDebug("show settings")
			self.performSegue(withIdentifier: "ShowSettings", sender: self)
			alert.dismiss(animated: true, completion: nil)
		})
		if #available(iOS 13.0, *) {
			// add system icons on iOS 13+
			infoAction.setValue(UIImage.init(systemName: "info.circle"), forKey: "image")
			settingsAction.setValue(UIImage.init(systemName: "gear"), forKey: "image")
		}
		alert.addAction(cancelAction)
		alert.addAction(infoAction)
		alert.addAction(settingsAction)
		alert.modalPresentationStyle = .popover
		present(alert, animated: true, completion: nil)
	}

	/// show/hide nav bar and player controls on long press
	@IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
		if sender.state == .began {
			printDebug("PlayerViewController: long press began")
		}
		else if sender.state == .ended {
			printDebug("PlayerViewController: long press ended")
			toggleControlVisibility()
		}
		else if sender.state == .cancelled {
			printDebug("PlayerViewController: long press cancelled")
		}
	}

	// MARK: PickerDelegate

	func pickerDidPick(_picker: Picker, urls: [URL]) {
		let url = urls[0] as URL
		if url.isFileURL && url.hasDirectoryPath {
			// speedpitch directory
			printDebug("PlayerViewController: directory not implemented \(url)")
		}
		else if url.pathExtension == "json" {
			// speedpitch json
			printDebug("PlayerViewController: json not implemented \(url)")
		}
		else {
			// audio file
			player = nil
			self.controlsView.player = nil
			player = SongMedia(url: url)
			if self.player != nil {
				printDebug("PlayerViewController: media url \(url)")
				self.player?.delegate = self
				self.controlsView.player = self.player
				self.player?.loop = true
				self.player?.play()
				self.player?.rate = rate
			}
			else {
				print("PlayerViewController: media url nil")
			}
		}
	}

	// MARK: MediaDelegate

	func mediaDidStartPlaying(_ media: Media) {
		printDebug("started playing")
		controlsView.update()
	}

	func mediaDidPausePlaying(_ media: Media) {
		printDebug("paused")
		controlsView.update()
	}

	func mediaDidFinishPlaying(_ media: Media) {
		printDebug("finished played")
		controlsView.update()
		player?.rewind()
	}

	// MARK: LocationDelegate

	func locationAuthorizationRestricted(_ location: Location) {
		let alert = UIAlertController(
			title: "Location Service Access Restricted",
			message: "To enable, please go to Settings and turn on Location Service for SpeedPitch.",
			preferredStyle: .alert
		)
		show(alert, sender: nil)
	}

	func locationAuthorizationDenied(_ location: Location) {
		let alert = UIAlertController(
			title: "Location Service Access Denied",
			message: "To enable, please go to Settings and turn on Location Service for SpeedPitch.",
			preferredStyle: .alert
		)
		show(alert, sender: nil)
	}

	func locationDidUpdateSpeed(_ location: Location, speed: Double, accuracy: Double) {
		printDebug("PlayerViewController: speed \(speed) accuracy \(accuracy)")
		//if accuracy >= 1 {return}
		var newRate = max(speed.mapped(from: 0...20.25, to: 0.05...1), 0.05)
		//var newRate = Double.random(in: 0.05...1)
		newRate = Double.mavg(old:rate, new: newRate, windowSize: 5)
		line.set(target: newRate, duration: 0.5) { value in
			self.rate = value
			if self.rate > 0 && self.player?.isPlaying ?? false {
				self.player?.rate = self.rate
			}
			self.dashboardView.update(speed: speed, rate: self.rate)
			//printDebug("rate \(self.rate)")
		}
	}
}
