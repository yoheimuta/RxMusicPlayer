//
//  ProgressSlider.swift
//  Example
//
//  Created by YOSHIMUTA YOHEI on 2019/09/18.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import UIKit

class ProgressSlider: UISlider {
    var playableProgress: Float = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        maximumTrackTintColor = .clear

        let c = UIGraphicsGetCurrentContext()
        let r = trackRect(forBounds: bounds)
        let path = UIBezierPath(roundedRect: r, cornerRadius: r.size.height / 2.0)
        c?.addPath(path.cgPath)
        c?.setLineWidth(0.1)

        UIColor.black.setStroke()
        c?.strokePath()

        c?.addPath(path.cgPath)
        c?.clip()

        UIColor.lightGray.setFill()
        c?.fill(CGRect(x: r.origin.x,
                       y: r.origin.y,
                       width: r.size.width,
                       height: r.size.height))

        UIColor.white.setFill()
        c?.fill(CGRect(x: r.origin.x,
                       y: r.origin.y,
                       width: r.size.width * CGFloat(playableProgress),
                       height: r.size.height))
    }
}
