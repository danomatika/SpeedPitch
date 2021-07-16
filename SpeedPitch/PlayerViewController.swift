//
//  PlayerViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class PlayerViewController: UIViewController, PickerDelegate, AudioPlayerDelegate, LocationDelegate {

	let audio = AudioEngine()
	let player = AudioPlayer()
	let playlist = Playlist()
	let picker = Picker()
	let location = Location()

	static var initRate: Double = 0.05
	static var initLocation: Bool = true
	static var randomRate: Bool = false

	var rate: Double = initRate // current playback rate
	let rateLine = Line(initRate)
	var rateTimestamp: TimeInterval = 0
	var speedlimit: Double = 20.25

	@IBOutlet weak var dashboardView: DashboardView!
	@IBOutlet weak var controlsView: ControlsView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		picker.delegate = self
		location.delegate = self
		rateTimestamp = Clock.now()

		// keep screen awake
		UIApplication.shared.isIdleTimerDisabled = true

		// start background clock
		Scheduler.shared.start()

		// setup audio
		player.delegate = self
		controlsView.playerViewController = self
		AudioEngine.activateSession()
		audio.setup()
		audio.attach(player: player)
		audio.start()

		// go
		if(PlayerViewController.initLocation) {
			location.enable()
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowPlaylist",
		   let scene = segue.destination as? UINavigationController,
		   let controller = scene.viewControllers.first as? PlaylistViewController  {
			controller.playerViewController = self
			controller.playlist = playlist
		}
		else if segue.identifier == "ShowSpeed",
		   let scene = segue.destination as? UINavigationController,
		   let controller = scene.viewControllers.first as? SpeedViewController  {
			controller.playerViewController = self
		}
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

	func updateControls() {
		DispatchQueue.main.async {self.controlsView.update()}
	}

	// MARK: Transport

	func play() {
		if !player.isOpen {
			goto(index: 0)
		}
		player.play()
		updateControls()
	}

	func pause() {
		player.pause()
		updateControls()
	}

	func togglePlay() {
		if player.isPlaying {
			pause()
		}
		else {
			play()
		}
	}

	func stop() {
		player.stop()
		updateControls()
	}

	// MARK: Playlist

	@discardableResult func prev() -> Bool {
		var file = playlist.current
		if playlist.isFirst {
			if playlist.isLooping {
				printDebug("PlayerViewController: playlist prev loop")
				// that was first file, loop the list?
				file = playlist.goto(index: playlist.count-1)
			}
			else {
				printDebug("PlayerViewController: playlist start")
				updateControls()
				return true
			}
		}
		else {
			printDebug("PlayerViewController: playlist prev")
			file = playlist.prev()
		}
		if file != nil {
			player.open(file: file!)
		}
		updateControls()
		return true
	}

	@discardableResult func next() -> Bool {
		var file = playlist.current
		if playlist.isLast {
			if playlist.isLooping {
				printDebug("PlayerViewController: playlist next loop")
				// that was last file, loop the list?
				file = playlist.goto(index: 0)
			}
			else {
				printDebug("PlayerViewController: playlist finished")
				updateControls()
				return false
			}
		}
		else {
			printDebug("PlayerViewController: playlist next")
			file = playlist.next()
		}
		if file != nil {
			player.open(file: file!)
		}
		updateControls()
		return true
	}

	@discardableResult func goto(index: Int) -> Bool {
		var ret = false
		let file = playlist.goto(index: index)
		if file != nil {
			player.open(file: file!)
			ret = true
		}
		updateControls()
		return ret
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
		let speedAction = UIAlertAction(title: "Speed", style: .default, handler: { action in
			printDebug("show speed")
			alert.dismiss(animated: true, completion: nil)
			self.performSegue(withIdentifier: "ShowSpeed", sender: self)
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
		alert.addAction(speedAction)
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

	func pickerDidPick(_picker: Picker, items: [PickedItem]) {
		for item in items {
			if item.url.isFileURL && item.url.hasDirectoryPath {
				// speedpitch directory
				printDebug("PlayerViewController: directory not implemented \(item.url)")
			}
			else if item.url.pathExtension == "json" {
				// speedpitch json
				printDebug("PlayerViewController: json not implemented \(item.url)")
			}
			else {
				// audio file
				player.close()
				guard let file = AudioFile(url: item.url) else {
					print("PlayerViewController: could not open \(item.url)")
					return
				}
				printDebug("PlayerViewController: media url \(item.url)")
				file.image = item.image
				playlist.add(file: file)
			}
		}
		self.updateControls()
	}

	// MARK: AudioPlayerDelegate

	func playerDidStartPlaying(_ player: AudioPlayer) {
		printDebug("started playing")
		self.updateControls()
	}

	func playerDidPausePlaying(_ player: AudioPlayer) {
		printDebug("paused")
		self.updateControls()
	}

	func playerDidFinishPlaying(_ player: AudioPlayer) {
		printDebug("finished playing")
		DispatchQueue.main.async {
			let wasPlaying = self.player.isPlaying
			if self.next() && wasPlaying {
				self.play()
			}
		}
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

			// calc new rate
			var newRate = self.rate
			if PlayerViewController.randomRate {
				newRate = Double.random(in: 0.05...2)
			}
			else {
				let maxspeed: Double = self.speedlimit / 3.6
				newRate = max(speed.mapped(from: 0...maxspeed, to: 0...1), 0.05)
			}
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
