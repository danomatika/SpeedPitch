//
//  PlayerViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController, PickerDelegate, MediaDelegate, LocationDelegate {

	let audio = AudioEngine()
	let player = AudioPlayer()
	let picker = Picker()
	let location = Location()

	var rate: Double = 0.05 // current playback rate
	let rateLine = Line(0.05)
	var rateTimestamp: TimeInterval = 0

	@IBOutlet weak var dashboardView: DashboardView!
	@IBOutlet weak var controlsView: ControlsView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		picker.delegate = self
		location.delegate = self
		location.enable()
		rateTimestamp = Clock.now()

		// keep screen awake
		UIApplication.shared.isIdleTimerDisabled = true

		// start background clock
		Scheduler.shared.start()

		// setup audio
		AudioEngine.activateSession()
		audio.setup()
		audio.attach(player: player)
		audio.start()
	}

	// toggle nav & controls visibility
	func toggleControlVisibility() {
		if let navBar = navigationController?.navigationBar {
			navigationController?.setNavigationBarHidden(!navBar.isHidden, animated: true)
		}
		UIView.transition(with: controlsView,
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
			player.close()
			guard let file = AudioFile(url: url) else {
				print("PlayerViewController: could not open \(url)")
				return
			}
			printDebug("PlayerViewController: media url \(url)")
			if player.open(file: file) {
				player.play()
				audio.rate = rate
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
		DispatchQueue.main.async {
			//let maxspeed: Double = 20.25 / 3.6
			//let newRate = max(speed.mapped(from: 0...maxspeed, to: 0...1), 0.05) // scales over 1 automatically
			let newRate = Double.random(in: 0.05...2)

			let delta = (Clock.now() - self.rateTimestamp).clamped(to: 0...5)
			self.rateTimestamp = Clock.now()

			// interpolate to new rate
			self.rateLine.set(target: newRate, duration: delta) { value in
				self.rate = value
				self.audio.rate = self.rate
				self.dashboardView.update(speed: speed, rate: self.rate)
			}
		}
	}

}
