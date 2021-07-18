//
//  SettingsViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

	weak var playerViewController: PlayerViewController?

	// display
	@IBOutlet weak var unitsControl: UISegmentedControl!
	@IBOutlet weak var keepAwakeSwitch: UISwitch!

	// rate
	@IBOutlet weak var quantizeSwitch: UISwitch!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		let defaults = UserDefaults.standard
		unitsControl.selectedSegmentIndex = defaults.integer(forKey: "units")
		keepAwakeSwitch.isOn = defaults.bool(forKey: "keepAwake")
		quantizeSwitch.isOn = defaults.bool(forKey: "quantize")
	}

	// update dashboard if units changed
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		playerViewController?.updateDashboard()
	}

	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func unitsChanged(_ sender: Any) {
		UserDefaults.standard.set(unitsControl.selectedSegmentIndex, forKey: "units")
	}

	@IBAction func keepAwakeChanged(_ sender: Any) {
		UserDefaults.standard.set(keepAwakeSwitch.isOn, forKey: "keepAwake")
		UIApplication.shared.isIdleTimerDisabled = self.keepAwakeSwitch.isOn
	}

	@IBAction func quantizeChanged(_ sender: Any) {
		UserDefaults.standard.set(quantizeSwitch.isOn, forKey: "quantize")
	}
}
