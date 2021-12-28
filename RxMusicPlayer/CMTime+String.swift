//
//  CMTime+String.swift
//  Example
//
//  Created by YOSHIMUTA YOHEI on 2019/09/17.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation

extension CMTime {
    public var displayTime: String? {
        guard let sec = seconds?.rounded() else { return nil }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        if sec < 60 * 60 {
            formatter.allowedUnits = [.minute, .second]
        } else {
            formatter.allowedUnits = [.hour, .minute, .second]
        }
        return formatter.string(from: sec) ?? nil
    }

    public var seconds: Double? {
        let time = CMTimeGetSeconds(self)
        guard time.isNaN == false else { return nil }
        return time
    }
}
