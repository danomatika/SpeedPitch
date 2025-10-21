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

		// load defaults
		if let path = Bundle.main.path(forResource: "UserDefaults", ofType: "plist") {
			let defaults = NSDictionary(contentsOfFile: path)
			UserDefaults.standard.register(defaults: defaults as! [String : Any])
		}

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

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}

}

