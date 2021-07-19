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

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		tableView.allowsMultipleSelectionDuringEditing = true
		navigationItem.rightBarButtonItems = [editButtonItem, loopButton]
	}

	override func viewWillAppear(_ animated: Bool) {
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

	@IBAction func toggleLoop(_ sender: Any) {
		let button = sender as! UIBarButtonItem
		if let playlist = playlist {
			playlist.isLooping = !playlist.isLooping
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
			for indexPath in tableView.indexPathsForSelectedRows! {
				if playlist.currentIndex == indexPath.row {
					playerViewController?.player.close()
				}
				playlist.remove(at: indexPath.row)
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
			if file.artist != "unknown" && file.title != "unknown" {
				cell.textLabel?.text = file.title
				cell.detailTextLabel?.text = file.artist
			}
			else {
				cell.textLabel?.text = file.description
				cell.detailTextLabel?.text = ""
			}
			if file.image != nil {
				cell.imageView?.image = file.image
			}
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

}
