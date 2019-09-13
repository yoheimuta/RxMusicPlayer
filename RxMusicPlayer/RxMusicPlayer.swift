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
open class RxMusicPlayer: NSObject {
    /**
     Player Status.
     */
    public enum Status {
        case ready
        case playing
        case paused
        case loading
        case failed(err: Error, cmd: Command)
    }

    /**
     Player Command.
     */
    public enum Command {
        case play
        case playAt(index: Int)
        case next
        case previous
        case pause
    }

    public var playIndex: Int {
        return playIndexRelay.value
    }

    public var queuedItems: [RxMusicPlayerItem] {
        return queuedItemsRelay.value
    }

    let playIndexRelay = BehaviorRelay<Int>(value: 0)
    let queuedItemsRelay = BehaviorRelay<[RxMusicPlayerItem]>(value: [])
    let statusRelay = BehaviorRelay<Status>(value: .ready)

    private let scheduler = ConcurrentDispatchQueueScheduler(
        queue: DispatchQueue(label: "com.github.yoheimuta.RxMusicPlayer.RxMusicPlayer",
                             qos: .background)
    )
    private var player: AVPlayer?

    /**
     Create an instance with a list of items without loading their assets.

     - parameter items: array of items to be added to the play queue

     - returns: RxMusicPlayer instance
     */
    public required init(items: [RxMusicPlayerItem] = [RxMusicPlayerItem]()) {
        queuedItemsRelay.accept(items)
        super.init()
    }

    /**
     Run a commmand.
     */
    public func run(cmd: Command) -> Driver<Status> {
        return { () -> Observable<Bool> in
            rx.canSendCommand(cmd: cmd).asObservable().take(1)
        }()
            .flatMapLatest { [weak self] isEnabled -> Observable<RxMusicPlayer.Status> in
                guard let weakSelf = self else {
                    return .error(RxMusicPlayerError.notFoundWeakReference)
                }
                if !isEnabled {
                    return .error(RxMusicPlayerError.invalidCommand(cmd: cmd))
                }
                switch cmd {
                case .play:
                    return weakSelf.play()
                case let .playAt(index: index):
                    return weakSelf.play(atIndex: index)
                case .next:
                    return weakSelf.playNext()
                case .previous:
                    return weakSelf.playPrevious()
                case .pause:
                    return weakSelf.pause()
                }
            }
            .asDriver(onErrorRecover: { e in
                .just(Status.failed(err: e, cmd: cmd))
            })
            .do(onNext: { [weak self] in self?.statusRelay.accept($0) })
    }

    private func play() -> Observable<Status> {
        return play(atIndex: playIndex)
    }

    private func play(atIndex index: Int) -> Observable<Status> {
        player?.pause()

        playIndexRelay.accept(index)
        statusRelay.accept(.loading)

        return queuedItems[playIndex].loadPlayerItem()
            .asObservable()
            .flatMap({ [weak self] item -> Observable<Status> in
                guard let weakSelf = self else {
                    return .error(RxMusicPlayerError.notFoundWeakReference)
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
            })
    }

    private func playNext() -> Observable<Status> {
        return play(atIndex: playIndex + 1)
    }

    private func playPrevious() -> Observable<Status> {
        return play(atIndex: playIndex - 1)
    }

    private func pause() -> Observable<Status> {
        player?.pause()
        statusRelay.accept(.paused)
        return statusRelay.asObservable()
    }
}
