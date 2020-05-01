//
//  PlaybackRateAction.swift
//  Example
//
//  Created by YOSHIMUTA YOHEI on 2020/04/26.
//  Copyright © 2020 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

enum PlaybackRateAction: String, CaseIterable {

    case x2 = "2x"
    case x1_5 = "1.5x"
    case x1_25 = "1.25x"
    case x1 = "1x"
    case x0_75 = "0.75x"
    case x0_5 = "0.5x"

    var toFloat: Float {
        switch self {
        case .x2:
            return 2
        case .x1_5:
            return 1.5
        case .x1_25:
            return 1.25
        case .x1:
            return 1
        case .x0_75:
            return 0.75
        case .x0_5:
            return 0.5
        }
    }
}
