//
//  Media.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/23/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

/// media playlist
class Playlist {

	var playlist: [AudioFile] = []
	var currentIndex: Int = 0
	var isLooping: Bool = false

	var isEmpty: Bool {return playlist.isEmpty}
	var count: Int {return playlist.count}
	var current: AudioFile? {
		get {
			if(playlist.isEmpty) {return nil}
			return playlist[currentIndex]
		}
	}
	var isFirst: Bool {
		get {return currentIndex == 0 && !playlist.isEmpty}
	}
	var isLast: Bool {
		get {return currentIndex == playlist.count-1}
	}

	func add(file: AudioFile) {
		if playlist.contains(where: {$0 === file}) {return}
		playlist.append(file)
	}

	func remove(file: AudioFile) {
		playlist.removeAll(where: {$0 === file})
	}

	func remove(at index: Int) {
		if(index < 0 || index >= playlist.count) {return}
		playlist.remove(at: index)
	}

	func clear() {
		currentIndex = 0
		playlist.removeAll()
	}

	func prev() -> AudioFile? {
		return goto(index: currentIndex - 1)
	}

	func next() -> AudioFile? {
		return goto(index: currentIndex + 1)
	}

	func goto(index: Int) -> AudioFile? {
		if playlist.isEmpty {return nil}
		if index < 0 || index >= playlist.count {return nil}
		currentIndex = index
		return current
	}

	func at(index: Int) -> AudioFile? {
		if index < 0 || index >= playlist.count {
			return nil
		}
		return playlist[index]
	}

	func move(index: Int, to: Int) {
		if let file = at(index: index) {
			playlist.remove(at: index)
			playlist.insert(file, at: to)
		}
	}

}
