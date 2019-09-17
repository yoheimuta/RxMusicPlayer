//
//  RxMusicPlayerItem+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import RxCocoa
import RxSwift

extension Reactive where Base: RxMusicPlayerItem {
    func meta() -> Driver<RxMusicPlayerItem.Meta> {
        return base.meta.didAllSetRelay
            .asDriver()
            .map { [weak base] didSet in
                didSet ? base?.meta : nil
            }
            .flatMap { Driver.from(optional: $0) }
    }
}
