//
//  AVAsset+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/13.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import RxSwift

extension Reactive where Base: AVAsset {

    var duration: Single<CMTime> {
        return loadAsync(for: "duration")
            .map { self.base.duration }
    }
}
