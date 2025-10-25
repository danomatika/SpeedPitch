//
//  PlaylistViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class PlaylistViewController: UITableViewController {

	weak var playerViewController: PlayerViewController?
	weak var playlist: Playlist?

	@IBOutlet weak var doneButton: UIBarButtonItem!
	@IBOutlet weak var loopButton: UIBarButtonItem!

	fileprivate var _editSwipe = false
	fileprivate var _defaultImage: UIImage?

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		_defaultImage = defaultFileImage(for: CGSize(width: 100, height: 100))

		tableView.tableFooterView = UIView(frame: .zero) // no empty rows
		tableView.allowsMultipleSelectionDuringEditing = true
		navigationItem.rightBarButtonItems = [editButtonItem, loopButton]
	}

	override func viewWillAppear(_ animated: Bool) {
		playerViewController?.playlistViewController = self
		navigationController?.isToolbarHidden = true
		updateLoopButton(loopButton)
		if !selectCurrentPlaylistRow() {
			editButtonItem.isEnabled = false
		}
	}

	// update prev/next buttons if playlist was cleared
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		playerViewController?.updateControls()
		playerViewController?.playlistViewController = nil
	}

	// update UI based on edit mode, called automatically by the Edit button
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		navigationController?.isToolbarHidden = !editing
		doneButton.isEnabled = !editing
		if !editing {
			selectCurrentPlaylistRow()
		}
	}

	/// select row for current playlist item, returns false if no item
	@discardableResult func selectCurrentPlaylistRow() -> Bool {
		if let playlist = playlist, !playlist.isEmpty {
			let indexPath = IndexPath(row: playlist.currentIndex, section: 0)
			tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			printDebug("PlaylistViewController: selected row \(indexPath.row)")
			return true
		}
		return false
	}

	// MARK: Actions

	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func togglePlaylistLoop(_ sender: Any) {
		guard let button = sender as? UIBarButtonItem else {return}
		if let playlist = playlist {
			playlist.isLooping = !playlist.isLooping
			UserDefaults.standard.set(playlist.isLooping, forKey: "loopPlaylist")
		}
		updateLoopButton(button)
		playerViewController?.updateControls()
	}

	@IBAction func deleteSelected(_ sender: Any) {
		guard let count = tableView.indexPathsForSelectedRows?.count,
			  let playlist = playlist else {return}
		if count >= playlist.count {
			playlist.clear()
			playerViewController?.player.close()
		}
		else {
			if let paths = tableView.indexPathsForSelectedRows {
				for indexPath in paths {
					if playlist.currentIndex == indexPath.row {
						playerViewController?.player.close()
					}
					playlist.remove(at: indexPath.row)
				}
			}
		}
		tableView.reloadData()
	}

	@IBAction func toggleFileLoop(_ sender: Any) {
		guard let playlist = playlist,
		      let paths = tableView.indexPathsForSelectedRows else {return}
		for indexPath in paths {
			if let file = playlist.at(index: indexPath.row) {
				file.loop = !file.loop
			}
		}
		tableView.reloadData()
	}

	override func selectAll(_ sender: (Any)?) {
		for r in 0...tableView.numberOfRows(inSection: 0) {
			tableView.selectRow(at: IndexPath(row: r, section: 0), animated: true, scrollPosition: .none)
		}
	}

	// MARK: UITableViewController

	// table length
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return playlist?.count ?? 0
	}

	// create cells from playlist files
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath)
		if let file = playlist?.at(index: indexPath.row) {

			// file info
			let prefix = (file.loop ? "🔂 " : "") // show loop state
			if file.artist != "unknown" && file.title != "unknown" {
				cell.textLabel?.text = prefix + file.title
				cell.detailTextLabel?.text = file.artist
			}
			else {
				cell.textLabel?.text = prefix + file.description
				cell.detailTextLabel?.text = ""
			}

			// image
			cell.imageView?.image = (file.image != nil ? file.image : _defaultImage)
		}
		return cell
	}

	/// play file on selection
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if tableView.isEditing {return}
		DispatchQueue.main.async {
			self.playerViewController?.goto(index: indexPath.row)
			self.playerViewController?.play()
		}
	}

	// all cells can be edited
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	// disable edit button on swipe action
	override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
		editButtonItem.isEnabled = false
	}

	// enable edit button after swipe action
	override func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
		editButtonItem.isEnabled = true
	}

	// remove on swipe to delete
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if(editingStyle == .delete) {
			if playlist?.currentIndex == indexPath.row {
				playerViewController?.player.stop()
			}
			playlist?.remove(at: indexPath.row)
			tableView.reloadData()
		}
	}

	// disable swipe to delete in edit mode
	override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		if tableView.isEditing {
			return .none
		}
		else {
			return .delete
		}
	}

	// enable row reordering in edit mode
	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return tableView.isEditing
	}

	// custom loop swipe actions for individual files
	override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

		// loop/unloop
		if let file = playlist?.at(index: indexPath.row) {
			let title = (file.loop ? "Unloop" : "Loop")
			let loop = UIContextualAction(style: .normal, title: title, handler: {  (contextualAction, view, boolValue) in
				file.loop = !file.loop
				self.tableView.reloadRows(at: [indexPath], with: .automatic) // reload to see title loop symbol
			})
			loop.backgroundColor = (file.loop ? .systemBlue : .systemGray)
			loop.image = UIImage(systemName: "repeat.1")
			return UISwipeActionsConfiguration(actions: [loop])
		}

		return nil
	}

	// remove individual files by swiping
	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

		// delete
		let delete = UIContextualAction(style: .destructive, title: "Delete", handler: {  (contextualAction, view, boolValue) in
			guard let playlist = self.playlist else {return}
			if playlist.currentIndex == indexPath.row {
				self.playerViewController?.player.close()
			}
			playlist.remove(at: indexPath.row)
			self.tableView.reloadData()
		})
		delete.backgroundColor = .systemRed
		delete.image = UIImage(systemName: "trash")

		return UISwipeActionsConfiguration(actions: [delete])
	}

	// perform move after reordering
	override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		playlist?.move(index: sourceIndexPath.row, to: destinationIndexPath.row)
	}

	// MARK: Private

	// show loop state via tint
	private func updateLoopButton(_ button: UIBarButtonItem) {
		if let playlist = playlist {
			if playlist.isLooping {
				loopButton.tintColor = tableView.tintColor
			}
			else {
				loopButton.tintColor = UIColor.systemGray
			}
		}
	}

	// generate default file image, use same size as images generated by picker
	private func defaultFileImage(for size: CGSize) -> UIImage? {
		let image = UIImage(systemName: "doc.fill")
		let renderer = UIGraphicsImageRenderer(size: size)
		let origin = CGPoint(x: size.width * 0.2, y: size.height * 0.2)
		let insetSize = CGSize(width: size.width * 0.6, height: size.height * 0.6)
		return renderer.image { (context) in
			UIColor.systemGray.set()
			image?.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: origin, size: insetSize))
		}
	}

}
