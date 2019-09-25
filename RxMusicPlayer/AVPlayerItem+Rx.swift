//
//  AVPlayerItem+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/25.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import RxCocoa
import RxSwift

extension Reactive where Base: AVPlayerItem {

    var loadedTimeRanges: Observable<[NSValue]> {
        return observe(
            [NSValue].self, #keyPath(AVPlayerItem.loadedTimeRanges)
        ).map { $0 ?? [] }
    }

    var status: Observable<AVPlayerItem.Status> {
        return observe(
            AVPlayerItem.Status.self, #keyPath(AVPlayerItem.status)
        ).map { $0 ?? .unknown }
    }
}
