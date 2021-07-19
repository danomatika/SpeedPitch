//
//  SpeedLimitView.swift
//  SpeedPitch
//
//  Created by Dan Wilcox on 7/19/21.
//  Copyright © 2021 Dan Wilcox. All rights reserved.

import UIKit

/// speed limit sign view
class SpeedLimitView : UIView {

	let strokeWidth: CGFloat = 20

	override func draw(_ rect: CGRect) {
		guard let context = UIGraphicsGetCurrentContext() else {return}
		let hsw = strokeWidth / 2
		let r = CGRect(x: rect.origin.x + hsw, y: rect.origin.y + hsw,
					   width: rect.size.width - strokeWidth,
					   height: rect.size.height - strokeWidth)
		context.setStrokeColor(UIColor.systemRed.cgColor)
		context.setLineWidth(strokeWidth)
		context.strokeEllipse(in: r)
	}

}
