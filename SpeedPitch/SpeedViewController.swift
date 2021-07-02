
import UIKit

class SpeedViewController: UIViewController {

	@IBOutlet weak var speedSlider: UISlider!
	@IBOutlet weak var speedTextField: UITextField!

	weak var playerViewController: PlayerViewController?

	override func viewDidLoad() {
		let speed = playerViewController?.speedlimit ?? 0
		speedTextField.text = "\(Int(speed.rounded()))"
	}

	// MARK: Actions

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func speedSliderChanged(_ sender: Any) {
		let speed = Double(speedSlider.value).mapped(from: 0...1, to: 3...30)
		playerViewController?.speedlimit = speed
		speedTextField.text = "\(Int(speed.rounded()))"
	}

}
