//
//  RxMusicPlayer+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import RxCocoa
import RxSwift

extension RxMusicPlayer: ReactiveCompatible {}

extension Reactive where Base: RxMusicPlayer {
    public var status: Driver<RxMusicPlayer.Status> {
        return base.statusRelay.asDriver()
    }
}
