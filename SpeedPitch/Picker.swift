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

	/// receive picked urls & metadata,
	/// call url.startAccessingSecurityScopedResource() before reading files
	/// otherwise document picker url will fail due to access permissions:
	///     let scoped = url.startAccessingSecurityScopedResource()
	///     use url...
	///     if scoped {url.stopAccessingSecurityScopedResource()}
	func pickerDidPick(_picker: Picker, items: [PickedItem])
}

struct PickedItem {
	let url: URL
	let image: UIImage?
}

/// media & document picker manager
class Picker: NSObject, MPMediaPickerControllerDelegate, UIDocumentPickerDelegate {

	var allowMultiple = true //< allow picking multiple items?
	var delegate: PickerDelegate?

	/// present media picker from a view controller
	func presentMediaPickerFrom(controller: UIViewController, sender: Any?) {
		let picker = MPMediaPickerController(mediaTypes: .music)
		picker.allowsPickingMultipleItems = allowMultiple
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
			picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio])
			//[UTType.audio, UTType.directory, UTType.json]
		}
		else {
			picker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .open)
		}
		picker.allowsMultipleSelection = allowMultiple
		picker.popoverPresentationController?.sourceView = sender as? UIView
		picker.delegate = self
		picker.shouldShowFileExtensions = true
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
		var items: [PickedItem] = []
		for mediaItem in mediaItemCollection.items {
			if let url = mediaItem.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
				printDebug("Picker: media item url \(url)")
				var image: UIImage? = nil
				if let artwork = mediaItem.value(forProperty: MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
					image = artwork.image(at: CGSize(width: 100, height: 100))
				}
				items.append(PickedItem(url: url, image: image))
			}
			else {
				printDebug("Picker: media item missing url: \(mediaItem)")
			}
		}
		delegate?.pickerDidPick(_picker: self, items: items)
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
		var items: [PickedItem] = []
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
						//items.append(PickedItem(url: url, image: nil))
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
				//items.append(PickedItem(url: url, image: nil))
			}
			else { // assume audio file
				print("Picker: audio file")
				items.append(PickedItem(url: url, image: nil))
			}
		}
		delegate?.pickerDidPick(_picker: self, items: items)
	}

	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		printDebug("Picker: document picker cancelled")
		controller.dismiss(animated: true, completion: nil)
	}

}
