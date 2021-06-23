//
//  SettingsViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	@IBAction func cancel(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}
}
