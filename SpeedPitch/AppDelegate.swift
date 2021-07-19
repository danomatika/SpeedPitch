//
//  AppDelegate.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/20/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var playerViewController: PlayerViewController?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	/// pass on url
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		let item = PickedItem(url: url, image: nil)
		if let playerViewController = playerViewController {
			playerViewController.pickerDidPick(_picker: playerViewController.picker, items: [item])
		}
		return true
	}

}

