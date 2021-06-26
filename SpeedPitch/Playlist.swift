//
//  Media.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/23/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

/// media playlist
class Playlist {

	var playlist: [Media] = []
	var currentIndex: Int = 0

	var current: Media? {
		get {
			if(currentIndex < 0 || currentIndex > playlist.count) {
				return nil
			}
			return playlist[currentIndex]
		}
		set {}
	}

	func add(media: Media) {

	}

	func clear() {

	}

	func prev() -> Media? {
		return nil
	}

	func next() -> Media? {
		return nil
	}

	func goto(index: Int) -> Media? {
		return nil
	}

}
