//
//  AVAsynchronousKeyValueLoading+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import RxSwift

extension Reactive where Base: AVAsynchronousKeyValueLoading {

    func loadAsync(for key: String) -> Single<()> {
        return Single.create { observer in
            self.base.loadValuesAsynchronously(forKeys: [key]) {
                var error: NSError?
                let status = self.base.statusOfValue(forKey: key, error: &error)
                switch status {
                case .loaded:
                    observer(.success(()))
                default:
                    observer(.error(error ?? NSError()))
                }
            }
            return Disposables.create()
        }
    }
}
