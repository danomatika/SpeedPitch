//
//  PlayerViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit
import MediaPlayer

class PlayerViewController: UIViewController, MPMediaPickerControllerDelegate, UIDocumentPickerDelegate {

	@IBOutlet weak var controlsView: ControlsView!

	var player: AVPlayer? = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
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

	/// show documents picker
	@IBAction func selectDocuments(_ sender: Any) {
		printDebug("PlayerViewController: selectDocuments")
		let controller = UIDocumentPickerViewController(documentTypes: [], in: .open)
		controller.allowsMultipleSelection = true
		controller.popoverPresentationController?.sourceView = sender as? UIView
		controller.delegate = self
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

	// MARK: MPMediaPickerControllerDelegate

	func mediaPicker(_ mediaPicker: MPMediaPickerController,
					 didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
		printDebug("PlayerViewController: media picker picked \(mediaItemCollection.count) items")
		mediaPicker.dismiss(animated: true)

		if mediaItemCollection.items.count == 0 {
			return
		}
		let item = mediaItemCollection.items.first
		if let url = item?.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
			printDebug("PlayerViewController: media assetURL \(url)")
			let playerItem = AVPlayerItem(url: url)
			if self.player == nil {
				self.player = AVPlayer(playerItem: playerItem)
				self.controlsView.player = self.player
			}
			else {
				self.player?.replaceCurrentItem(with: playerItem)
			}
			self.player?.currentItem?.audioTimePitchAlgorithm = .varispeed
			self.player?.play()
			self.player?.rate = 1.0
			self.controlsView.isPlaying = true

			let title = item?.value(forProperty: MPMediaItemPropertyArtist) as? String ?? "unknown"
			let artist = item?.value(forProperty: MPMediaItemPropertyTitle) as? String ?? "unknown"
			self.controlsView.titleAndArtistLabel.text = "\(title) - \(artist)"
		}
		else {
			print("PlayerViewController: media assetURL nil")
		}
	}

	func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
		printDebug("PlayerViewController: media picker dismissed")
		mediaPicker.dismiss(animated: true)
	}

}
