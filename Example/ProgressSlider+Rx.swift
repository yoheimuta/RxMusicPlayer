//
//  ProgressSlider+Rx.swift
//  Example
//
//  Created by YOSHIMUTA YOHEI on 2019/09/18.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

extension Reactive where Base: ProgressSlider {
    var playableProgress: Binder<Float?> {
        return Binder(base) { field, value in
            field.playableProgress = value ?? 0
            field.setNeedsDisplay()
        }
    }
}
