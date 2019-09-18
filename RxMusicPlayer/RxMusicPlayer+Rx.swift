//
//  RxMusicPlayer+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import RxAudioVisual
import RxCocoa
import RxSwift

extension Reactive where Base: RxMusicPlayer {
    /**
     Predicate about whether or not sending the given command.
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
        case .stop:
            return .just(true)
        }
    }

    /**
     Get the current item's title.
     */
    public func currentItemTitle() -> Driver<String?> {
        return currentItemMeta()
            .map { $0.title }
    }

    /**
     Get the current item's duration.
     */
    public func currentItemDuration() -> Driver<CMTime?> {
        return currentItemMeta()
            .map { $0.duration }
    }

    /**
     Get the current item's duration formatting like "0:20".
     */
    public func currentItemDurationDisplay() -> Driver<String?> {
        return currentItemDuration()
            .map { $0?.displayTime ?? "0:00" }
    }

    /**
     Get the current item's curret time.
     */
    public func currentItemTime() -> Driver<CMTime?> {
        return base.playerRelay.asDriver()
            .flatMapLatest { player in
                guard let weakPlayer = player else {
                    return .just(nil)
                }
                return weakPlayer.rx.periodicTimeObserver(interval:
                    CMTimeMakeWithSeconds(0.05, preferredTimescale: Int32(NSEC_PER_SEC)))
                    .map { t -> CMTime? in t }
                    .asDriver(onErrorJustReturn: nil)
            }
    }

    /**
     Get the current item's curret time formatting like "0:20".
     */
    public func currentItemTimeDisplay() -> Driver<String?> {
        return currentItemTime()
            .map { $0?.displayTime ?? "0:00" }
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

    private func currentItem() -> Driver<RxMusicPlayerItem?> {
        return base.playIndexRelay.asDriver()
            .map { [weak base] index in
                guard let items = base?.queuedItems else { return nil }
                return index < items.count ? items[index] : nil
            }
    }

    private func currentItemMeta() -> Driver<RxMusicPlayerItem.Meta> {
        return currentItem()
            .flatMap { Driver.from(optional: $0) }
            .flatMapLatest { item -> Driver<RxMusicPlayerItem.Meta> in
                item.rx.meta()
            }
    }
}
