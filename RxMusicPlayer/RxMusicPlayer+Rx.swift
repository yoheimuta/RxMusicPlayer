//
//  RxMusicPlayer+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
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
        case .seek:
            return canSeek()
        case .prefetch:
            return canPrefetch()
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
     Get the current item's artwork.
     */
    public func currentItemArtwork() -> Driver<UIImage?> {
        return currentItemMeta()
            .map { $0.artwork }
    }

    /**
     Get the current item's album.
     */
    public func currentItemAlbum() -> Driver<String?> {
        return currentItemMeta()
            .map { $0.album }
    }

    /**
     Get the current item's artist.
     */
    public func currentItemArtist() -> Driver<String?> {
        return currentItemMeta()
            .map { $0.artist }
    }

    /**
     Get the current item's lyrics.
     */
    public func currentItemLyrics() -> Driver<String?> {
        return currentItemMeta()
            .map { $0.lyrics }
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
            .map { $0?.displayTime ?? "--:--" }
    }

    /**
     Get the current item's rest duration.
     */
    public func currentItemRestDuration() -> Driver<CMTime?> {
        return Driver.combineLatest(
            currentItemDuration(),
            currentItemTime()
        ) { duration, currentTime in
            guard let ltime = duration else { return nil }
            guard let rtime = currentTime else { return ltime }
            return CMTimeSubtract(ltime, rtime)
        }
    }

    /**
     Get the current item's rest duration formatting like "0:20".
     */
    public func currentItemRestDurationDisplay() -> Driver<String?> {
        return currentItemRestDuration()
            .map { $0?.displayTime ?? "--:--" }
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
            .map { $0?.displayTime ?? "00:00" }
    }

    /**
     Get the current item's progress rate(0.0 ~ 1.0).
     */
    public func currentItemLoadedProgressRate() -> Driver<Float?> {
        return Driver.combineLatest(
            currentItemDuration(),
            currentItemLoadedTimeRange()
        ) { maybeDuration, maybeRange in
            guard let duration = maybeDuration?.seconds,
                let end = maybeRange?.end.seconds else {
                return nil
            }
            return Float(end / duration)
        }
    }

    /**
     Get the current item's loaded time range.
     */
    public func currentItemLoadedTimeRange() -> Driver<CMTimeRange?> {
        return currentPlayerItem()
            .flatMap { Driver.from(optional: $0) }
            .asObservable()
            .flatMapLatest { item in
                item.rx.loadedTimeRanges
                    .map { $0.last as? CMTimeRange }
            }
            .asDriver(onErrorJustReturn: nil)
    }

    /**
     Get the current time control status.
     */
    @available(iOS 10.0, *)
    public func timeControlStatus() -> Observable<AVPlayer.TimeControlStatus> {
        return base.playerRelay.asObservable()
            .flatMap { Observable.from(optional: $0) }
            .flatMapFirst { player in
                player.rx.avPlayertimeControlStatus
            }
    }

    /**
     Get the current player item.
     */
    public func currentPlayerItem() -> Driver<AVPlayerItem?> {
        return base.playerRelay.asDriver()
            .map { $0?.currentItem }
    }

    /**
     Get the current item.
     */
    public func currentItem() -> Driver<RxMusicPlayerItem?> {
        return playerIndex()
            .map { [weak base] index in
                guard let items = base?.queuedItems else { return nil }
                return index < items.count ? items[index] : nil
            }
    }

    /**
     Get the current item' meta information.
     */
    public func currentItemMeta() -> Driver<RxMusicPlayerItem.Meta> {
        return currentItem()
            .flatMap { Driver.from(optional: $0) }
            .flatMapLatest { item -> Driver<RxMusicPlayerItem.Meta> in
                item.rx.meta()
            }
    }

    /**
     Get the shuffle mode.
     */
    public func shuffleMode() -> Driver<RxMusicPlayer.ShuffleMode> {
        return base.shuffleModeRelay.asDriver()
    }

    /**
     Get the repeat mode.
     */
    public func repeatMode() -> Driver<RxMusicPlayer.RepeatMode> {
        return base.repeatModeRelay.asDriver()
    }

    /**
     Get the player index.
     */
    public func playerIndex() -> Driver<Int> {
        return base.playIndexRelay.asDriver()
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
            playerIndex(),
            base.queuedItemsRelay.asDriver()
        )
        .map({ index, items in
            index + 1 < items.count
        })
    }

    private func canPrevious() -> Driver<Bool> {
        return playerIndex()
            .flatMapLatest { [weak base] index in
                if 0 < index {
                    return .just(true)
                }
                guard let weakBase = base else { return .just(false) }
                return weakBase.rx.currentItemTime()
                    .map { 1 < ($0?.seconds ?? 0) }
            }
    }

    private func canSeek() -> Driver<Bool> {
        return Driver.combineLatest(
            base.playerRelay.asDriver(),
            base.statusRelay.asDriver()
        ) { player, status in
            if player == nil {
                return false
            }
            return ([
                .ready,
                .playing,
                .paused,
            ] as [RxMusicPlayer.Status]).contains(status)
        }
    }

    private func canPrefetch() -> Driver<Bool> {
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
}
