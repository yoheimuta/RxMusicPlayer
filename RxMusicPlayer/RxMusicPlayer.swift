//
//  RxMusicPlayer.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import Foundation
import RxAudioVisual
import RxCocoa
import RxSwift

/// RxMusicPlayer is a wrapper of avplayer to make it easy for audio playbacks.
///
/// RxMusicPlayer is thread safe.
open class RxMusicPlayer {
    /**
     Player Status.
     */
    public enum Status {
        case ready
        case playing
        case paused
        case loading
    }

    let statusRelay = BehaviorRelay<Status>(value: .ready)

    private let scheduler = ConcurrentDispatchQueueScheduler(
        queue: DispatchQueue(label: "com.github.yoheimuta.RxMusicPlayer.RxMusicPlayer",
                             qos: .background)
    )
    private var player: AVPlayer?
    private var queuedItems: [RxMusicPlayerItem]
    private var playIndex = 0

    /**
     Create an instance with a list of items without loading their assets.

     - parameter items: array of items to be added to the play queue

     - returns: RxMusicPlayer instance
     */
    public required init?(items: [RxMusicPlayerItem] = [RxMusicPlayerItem]()) {
        queuedItems = items
    }

    /**
     Starts item playback.
     */
    public func play() -> Observable<Status> {
        return play(atIndex: playIndex)
    }

    /**
     Plays the item indicated by the passed index

     - parameter index: index of the item to be played
     */
    public func play(atIndex index: Int) -> Observable<Status> {
        playIndex = index

        player?.pause()
        return queuedItems[playIndex].loadPlayerItem()
            .observeOn(scheduler)
            .asObservable()
            .flatMap({ [weak self] item -> Observable<Status> in
                guard let weakSelf = self else {
                    return .error(RxMusicPlayerError.abort)
                }
                let player = AVPlayer(playerItem: item?.playerItem)
                weakSelf.player = player
                weakSelf.player!.automaticallyWaitsToMinimizeStalling = false
                weakSelf.player!.play()
                return weakSelf.player!.rx.status
                    .map { status in
                        switch status {
                        case .readyToPlay: return .playing
                        case .failed: throw player.error!
                        default: return .loading
                        }
                    }
                    .do(onNext: { self?.statusRelay.accept($0) })
            })
    }

    /**
     Plays the next item in the queue.
     */
    public func playNext() -> Observable<Status> {
        return play(atIndex: playIndex + 1)
    }

    /**
     Plays the previous item in the queue
     */
    public func playPrevious() -> Observable<Status> {
        return play(atIndex: playIndex - 1)
    }
}
