//
//  DashboardView.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/23/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class DashboardView: UIView {

	let rateFormatter = NumberFormatter()

	@IBOutlet weak var speedLabel: UILabel! //< speed over ground
	@IBOutlet weak var rateLabel: UILabel! //< playback rate

	override func awakeFromNib() {
		rateFormatter.usesSignificantDigits = true
		rateFormatter.maximumSignificantDigits = 2
	}

	/// speed in m/s
	func update(speed: Double, rate: Double) {
		let units = UserDefaults.standard.integer(forKey: "units")
		if speed < 0 {
			switch units {
			case 1: // miles
				speedLabel.text = "?\nmph"
			default: // km
				speedLabel.text = "?\nkm/h"
			}
			rateLabel.text = ""
		}
		else {
			let converted = speed * 3.6 // m/s -> km/h
			switch units {
			case 1: // miles
				speedLabel.text = "\(Int((converted * 0.625).rounded()))\nmph"
			default: // km
				speedLabel.text = "\(Int(converted.rounded()))\nkm/h"
			}
			rateLabel.text = (rateFormatter.string(for: rate) ?? "1") + "x"
		}
	}

}
