//
//  RxMusicPlayer+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import RxCocoa
import RxSwift

extension Reactive where Base: RxMusicPlayer {
    /**
     Predicate about whether or not sending the given command
     */
    public func canSendCommand(cmd: RxMusicPlayer.Command) -> Driver<Bool> {
        switch cmd {
        case .play, .playAt:
            return canPlay()
        case .next:
            return canNext()
        case .previous:
            return canPrevious()
        case .pause:
            return canPause()
        }
    }

    private func canPlay() -> Driver<Bool> {
        return base.statusRelay.asDriver()
            .map { status in
                switch status {
                case .loading, .playing:
                    return false
                default:
                    return true
                }
            }
    }

    private func canPause() -> Driver<Bool> {
        return base.statusRelay.asDriver()
            .map { status in
                switch status {
                case .loading, .playing:
                    return true
                default:
                    return false
                }
            }
    }

    private func canNext() -> Driver<Bool> {
        return Driver.combineLatest(
            base.playIndexRelay.asDriver(),
            base.queuedItemsRelay.asDriver()
        )
        .map({ index, items in
            index + 1 < items.count
        })
    }

    private func canPrevious() -> Driver<Bool> {
        return base.playIndexRelay.asDriver()
            .map { 0 < $0 }
    }
}
