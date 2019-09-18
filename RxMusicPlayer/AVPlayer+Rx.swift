//
//  AVPlayer+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/18.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import RxSwift

extension Reactive where Base: AVPlayer {
    func periodicTimeObserver(interval: CMTime) -> Observable<CMTime> {
        return Observable.create { observer in
            let time = self.base.addPeriodicTimeObserver(forInterval: interval,
                                                         queue: nil) { time in
                observer.onNext(time)
            }
            return Disposables.create { self.base.removeTimeObserver(time) }
        }
    }
}
