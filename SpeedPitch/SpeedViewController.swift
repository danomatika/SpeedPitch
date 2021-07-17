
import UIKit

class SpeedViewController: UIViewController {

	@IBOutlet weak var speedSlider: UISlider!
	@IBOutlet weak var speedTextField: UITextField!

	weak var playerViewController: PlayerViewController?

	override func viewDidLoad() {
		let speed = playerViewController?.speedlimit ?? 0
		update(speed: speed)
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func speedSliderChanged(_ sender: Any) {
		let speed = Double(speedSlider.value).mapped(from: 0...1, to: 3...30)
		playerViewController?.speedlimit = speed
		update(speed: speed)
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

}
