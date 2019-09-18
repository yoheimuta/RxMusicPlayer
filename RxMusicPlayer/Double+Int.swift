//
//  Double+Int.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/18.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

extension Double {
    func toInt() -> Int? {
        if self >= Double(Int.min) && self < Double(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
}
