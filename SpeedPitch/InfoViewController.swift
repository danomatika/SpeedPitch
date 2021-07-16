//
//  InfoViewController.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 6/21/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

	@IBOutlet weak var textView: UITextView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		// load rtf into text view
//		if let path = Bundle.main.url(forResource: "AppInfo", withExtension: "rtf") {
//			do {
//				let text: NSAttributedString = try NSAttributedString(url: path, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
//				self.textView.attributedText = text
//			}
//			catch let error {
//				print("InfoViewController: could not open AppInfo.rtf: \(error)")
//			}
//		}
		if let path = Bundle.main.url(forResource: "AppInfo", withExtension: "txt") {
			do {
				let text: String = try String(contentsOf: path, encoding: .utf8)
				self.textView.text = text
			}
			catch let error {
				print("InfoViewController: could not open AppInfo.rtf: \(error)")
			}
		}
	}

	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

}
