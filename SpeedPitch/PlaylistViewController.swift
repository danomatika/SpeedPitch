//
//  PlaylistViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

struct PlaylistItem {

	var title: String = "unknown"
	var artist: String = "unknown"
	var url: URL? = nil
	var image: UIImage? = nil
	var meta: [String: AnyObject] = [:]
	var isLocal: Bool = false

}

class PlaylistViewController: UITableViewController {

	var playlist: [PlaylistItem] = []
	var current: UInt = 0

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		// test data
		self.playlist.append(PlaylistItem(title: "Song1", artist: "Dire Straits", url: nil, image: nil, meta: [:], isLocal: false))
		self.playlist.append(PlaylistItem(title: "Song2", artist: "Elvis Costello", url: nil, image: nil, meta: [:], isLocal: false))
		printDebug("PlaylistViewController: count \(self.playlist.count)")
	}

	@IBAction func cancel(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}

	// MARK: UITableViewController

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.playlist.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = self.playlist[indexPath.row]
		let cell = self.tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath)
		cell.textLabel?.text = item.title
		cell.detailTextLabel?.text = item.artist
		return cell
	}

}
