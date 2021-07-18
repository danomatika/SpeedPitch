
import UIKit

class SpeedViewController: UIViewController {

	weak var playerViewController: PlayerViewController?

	@IBOutlet weak var speedSlider: UISlider!
	@IBOutlet weak var speedTextField: UITextField!
	@IBOutlet weak var rangeControl: UISegmentedControl!

	override func viewDidLoad() {
		let defaults = UserDefaults.standard
		rangeControl.selectedSegmentIndex = defaults.integer(forKey: "range")

		let speedLimit = playerViewController?.speedLimit ?? 0
		update(speed: speedLimit)
	}

	// update UI with speed in km/h
	func update(speed: Double) {
		let units = UserDefaults.standard.integer(forKey: "units")
		switch units {
		case 1: // miles
			speedTextField.text = "\(Int((speed * 0.625).rounded()))\nmph"
		default: // km
			speedTextField.text = "\(Int(speed.rounded()))\nkm/h"
		}
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func speedSliderChanged(_ sender: Any) {
		let range = UserDefaults.standard.integer(forKey: "range")
		let maxSpeed = PlayerViewController.maxSpeeds[range]
		let speedLimit = Double(speedSlider.value).mapped(from: 0...1, to: 0...maxSpeed)
		playerViewController?.speedLimit = speedLimit
		UserDefaults.standard.set(speedLimit, forKey: "speedLimit")
		update(speed: speedLimit)
		printDebug("SpeedViewController: speed limit \(speedLimit)")
	}

	@IBAction func rangeChanged(_ sender: Any) {
		let range = rangeControl.selectedSegmentIndex
		UserDefaults.standard.set(range, forKey: "range")
		printDebug("SpeedViewController: range \(range)")

		// lower limit to within selected range
		let maxSpeed = PlayerViewController.maxSpeeds[range]
		if let speedLimit = playerViewController?.speedLimit {
			if speedLimit > maxSpeed {
				playerViewController?.speedLimit = maxSpeed
				speedSlider.value = 1
				update(speed: maxSpeed)
				printDebug("SpeedViewController: lowered limit limit to \(speedLimit)")
			}
			else {
				speedSlider.value = Float(speedLimit.mapped(from: 0...maxSpeed, to: 0...1).clamped(to: 0...1))
			}
		}
	}

}
