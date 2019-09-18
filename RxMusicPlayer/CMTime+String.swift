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
        guard let sec = seconds?.rounded().toInt() else { return nil }
        return String(format: "%d:%02d", sec / 60, sec % 60)
    }

    public var seconds: Double? {
        let time = CMTimeGetSeconds(self)
        guard time.isNaN == false else { return nil }
        return time
    }
}
