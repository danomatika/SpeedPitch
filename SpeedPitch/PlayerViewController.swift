//
//  PlayerViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerViewController: UIViewController, MediaDelegate, LocationDelegate, MPMediaPickerControllerDelegate, UIDocumentPickerDelegate {

	@IBOutlet weak var dashboardView: DashboardView!
	@IBOutlet weak var controlsView: ControlsView!

	var player: SongMedia? = nil
	let location = Location()

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		location.enable()
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
		let controller = MPMediaPickerController(mediaTypes: .music)
		controller.allowsPickingMultipleItems = false
		controller.popoverPresentationController?.sourceView = sender as? UIView
		controller.delegate = self
		present(controller, animated: true)
	}

	/// show documents picker, opens:
	/// * audio files
	/// * projects: directories with a speedpitch.json file or the json file directly
	@IBAction func selectDocuments(_ sender: Any) {
		printDebug("PlayerViewController: selectDocuments")
		var controller: UIDocumentPickerViewController
		if #available(iOS 14.0, *) {
			controller = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio, UTType.directory, UTType.json])
		}
		else {
			controller = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .open)
		}
		controller.allowsMultipleSelection = false
		controller.popoverPresentationController?.sourceView = sender as? UIView
		controller.delegate = self
		if #available(iOS 13.0, *) {
			controller.shouldShowFileExtensions = true
			controller.directoryURL = URL.documents // start in Documents
		}
		present(controller, animated: true)
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
		print("PlayerViewController: speed \(speed)")
	}

	// MARK: MPMediaPickerControllerDelegate

	func mediaPicker(_ mediaPicker: MPMediaPickerController,
					 didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
		printDebug("PlayerViewController: media picker picked \(mediaItemCollection.count) items")
		mediaPicker.dismiss(animated: true)
		if mediaItemCollection.items.count == 0 {
			return
		}
		if let item = mediaItemCollection.items.first {
			self.player = SongMedia(mediaItem: item)
			if self.player != nil {
				printDebug("PlayerViewController: media assetURL \(String(describing: self.player?.url))")
				self.player?.delegate = self
				self.controlsView.player = self.player
				self.player?.play()
				return

			}
			else {
				print("PlayerViewController: media assetURL nil")
				return
			}
		}
	}

	func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
		printDebug("PlayerViewController: media picker dismissed")
		mediaPicker.dismiss(animated: true)
	}

	// MARK: UIDocumentPickerDelegate

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		printDebug("PlayerViewController: document picker picked \(urls.count) items")
		controller.dismiss(animated: true, completion: nil)
		if urls.count == 0 {
			return
		}
		if let url = urls.first {
			printDebug("PlayerViewController: document assetURL \(url)")
			if url.hasDirectoryPath {
				print("PlayerViewController: directory")
				do {
					let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [])
					contents.forEach {suburl in
						if suburl.lastPathComponent == "speedpitch.json" {
							print("PlayerViewController: speedpitch directory")
							return
						}
					}
					print("PlayerViewController: ignoring, non-speedpitch directory")
				}
				catch {
					print("PlayerViewController: unable to read directory")
				}
				return
			}
			else if url.lastPathComponent == "speedpitch.json" {
				print("PlayerViewController: speedpitch file")
				return
			}
			else { // assume audio file
				print("PlayerViewController: audio file")
				self.player = SongMedia(url: url)
				if self.player != nil {
					self.player?.delegate = self
					self.controlsView.player = self.player
					self.player?.play()
				}
				else {
					print("PlayerViewController: unable to open audio file")
				}
			}
		}
		else {
			print("PlayerViewController: document assetURL nil")
		}
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		printDebug("PlayerViewController: document picker cancelled")
		controller.dismiss(animated: true, completion: nil)
	}

}
