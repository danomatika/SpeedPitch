//
//  Picker.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/24/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit
import MediaPlayer

/// picker manager event delegate
protocol PickerDelegate {
	func pickerDidPick(_picker: Picker, urls: [URL])
}

/// media & document picker manager
class Picker: NSObject, MPMediaPickerControllerDelegate, UIDocumentPickerDelegate {

	var delegate: PickerDelegate?

	/// present media picker from a view controller
	func presentMediaPickerFrom(controller: UIViewController, sender: Any?) {
		let picker = MPMediaPickerController(mediaTypes: .music)
		picker.allowsPickingMultipleItems = false
		picker.popoverPresentationController?.sourceView = sender as? UIView
		picker.delegate = self
		controller.present(picker, animated: true)
	}

	/// present document picker from a view controller, picks urls:
	/// * audio files
	/// * projects: directories with a speedpitch.json file or the json file directly
	func presentDocumentPickerFrom(controller: UIViewController, sender: Any?) {
		var picker: UIDocumentPickerViewController
		if #available(iOS 14.0, *) {
			picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio, UTType.directory, UTType.json])
		}
		else {
			picker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .open)
		}
		picker.allowsMultipleSelection = false
		picker.popoverPresentationController?.sourceView = sender as? UIView
		picker.delegate = self
		if #available(iOS 13.0, *) {
			picker.shouldShowFileExtensions = true
			picker.directoryURL = URL.documents // start in Documents
		}
		controller.present(picker, animated: true)
	}

	// MARK: MPMediaPickerControllerDelegate

	func mediaPicker(_ mediaPicker: MPMediaPickerController,
					 didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
		printDebug("Picker: picked \(mediaItemCollection.count) media items")
		mediaPicker.dismiss(animated: true)
		if mediaItemCollection.items.count == 0 {
			return
		}
		var mediaUrls: [URL] = []
		for mediaItem in mediaItemCollection.items {
			if let url = mediaItem.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
				printDebug("Picker: media item url \(url)")
				mediaUrls.append(url)
			}
			else {
				printDebug("Picker: media item missing url: \(mediaItem)")
			}
		}
		delegate?.pickerDidPick(_picker: self, urls: mediaUrls)
	}

	func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
		printDebug("Picker: media picker cancelled")
		mediaPicker.dismiss(animated: true)
	}

	// MARK: UIDocumentPickerDelegate

	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		printDebug("Picker: picked \(urls.count) document items")
		controller.dismiss(animated: true, completion: nil)
		if urls.count == 0 {
			return
		}
		var mediaUrls: [URL] = []
		for url in urls {
			printDebug("Picker: document url \(url)")
			if url.hasDirectoryPath {
				print("Picker: directory")
				do {
					let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: [])
					var found = false
					for suburl in contents {
						if suburl.lastPathComponent == "speedpitch.json" {
							found = true
							break
						}
					}
					if found {
						print("Picker: speedpitch directory")
						mediaUrls.append(url)
					}
					else {
						print("Picker: ignoring, non-speedpitch directory")
					}
				}
				catch {
					print("Picker: unable to read directory")
				}
			}
			else if url.lastPathComponent == "speedpitch.json" {
				print("Picker: speedpitch file")
				mediaUrls.append(url)
			}
			else { // assume audio file
				print("Picker: audio file")
				mediaUrls.append(url)
			}
		}
		delegate?.pickerDidPick(_picker: self, urls: mediaUrls)
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		printDebug("Picker: document picker cancelled")
		controller.dismiss(animated: true, completion: nil)
	}

}
