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
    public enum Status: Equatable {
        public static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.ready, .ready),
                 (.playing, .playing),
                 (.paused, .paused),
                 (.loading, .loading):
                return true
            default:
                return false
            }
        }

        case ready
        case playing
        case paused
        case loading
        case failed(err: Error)
        case critical(err: Error)
    }

    /**
     Player Command.
     */
    public enum Command: Equatable {
        case play
        case playAt(index: Int)
        case next
        case previous
        case pause

        public static func == (lhs: Command, rhs: Command) -> Bool {
            switch (lhs, rhs) {
            case (.play, .play),
                 (.next, .next),
                 (.previous, .previous),
                 (.pause, .pause):
                return true
            case let (.playAt(lindex), .playAt(index: rindex)):
                return lindex == rindex
            default:
                return false
            }
        }
    }

    public var playIndex: Int {
        return playIndexRelay.value
    }

    public var queuedItems: [RxMusicPlayerItem] {
        return queuedItemsRelay.value
    }

    public var status: Status {
        return statusRelay.value
    }

    let playIndexRelay = BehaviorRelay<Int>(value: 0)
    let queuedItemsRelay = BehaviorRelay<[RxMusicPlayerItem]>(value: [])
    let statusRelay = BehaviorRelay<Status>(value: .ready)

    private let scheduler = ConcurrentDispatchQueueScheduler(
        queue: DispatchQueue(label: "com.github.yoheimuta.RxMusicPlayer.RxMusicPlayer",
                             qos: .background)
    )
    private let playerRelay = BehaviorRelay<AVPlayer?>(value: nil)
    private var player: AVPlayer? {
        set {
            playerRelay.accept(newValue)
        }
        get {
            return playerRelay.value
        }
    }

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
     Run loop.
     */
    public func loop(cmd: Driver<Command>) -> Driver<Status> {
        return Driver.combineLatest(
            statusRelay.asDriver(),
            playerRelay.asDriver()
                .flatMapLatest { p -> Driver<()> in
                    guard let weakPlayer = p else {
                        return .just(())
                    }
                    return weakPlayer.rx.status
                        .map { [weak self] st in
                            switch st {
                            case .failed: self?.statusRelay.accept(.critical(err: weakPlayer.error!))
                            default:
                                break
                            }
                        }
                        .asDriver(onErrorJustReturn: ())
                }
                .distinctUntilChanged { true },
            cmd
                .flatMapLatest(runCommand)
                .distinctUntilChanged { true }
        )
        .map { $0.0 }
        .distinctUntilChanged()
    }

    private func runCommand(cmd: Command) -> Driver<()> {
        return { () -> Observable<Bool> in
            rx.canSendCommand(cmd: cmd).asObservable().take(1)
        }()
            .flatMapLatest { [weak self] isEnabled -> Observable<()> in
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
            .catchError { [weak self] err in
                self?.statusRelay.accept(.failed(err: err))
                return .just(())
            }
            .asDriver(onErrorJustReturn: ())
    }

    private func play() -> Observable<()> {
        return play(atIndex: playIndex)
    }

    private func play(atIndex index: Int) -> Observable<()> {
        if playIndex == index && status == .paused {
            return resume()
        }

        player?.pause()

        playIndexRelay.accept(index)
        statusRelay.accept(.loading)

        return queuedItems[playIndex].loadPlayerItem()
            .asObservable()
            .flatMapLatest { [weak self] item -> Observable<()> in
                guard let weakSelf = self, let weakItem = item else {
                    return .error(RxMusicPlayerError.notFoundWeakReference)
                }
                let player = AVPlayer(playerItem: weakItem.playerItem)
                weakSelf.player = player
                weakSelf.player!.automaticallyWaitsToMinimizeStalling = false
                weakSelf.player!.play()
                return weakItem.playerItem!.rx.status
                    .map { [weak self] st in
                        switch st {
                        case .readyToPlay: self?.statusRelay.accept(.playing)
                        case .failed: throw weakItem.playerItem!.error!
                        default: break
                        }
                    }
            }
            .flatMapLatest { [weak self] _ -> Observable<()> in
                guard let weakSelf = self else { return .empty() }
                return weakSelf.preload(index: index)
            }
    }

    private func playNext() -> Observable<()> {
        return play(atIndex: playIndex + 1)
    }

    private func playPrevious() -> Observable<()> {
        return play(atIndex: playIndex - 1)
    }

    private func pause() -> Observable<()> {
        player?.pause()
        statusRelay.accept(.paused)
        return .just(())
    }

    private func resume() -> Observable<()> {
        player?.play()
        statusRelay.accept(.playing)
        return .just(())
    }

    private func preload(index: Int) -> Observable<()> {
        var items: [RxMusicPlayerItem] = []
        if index - 1 >= 0 {
            items.append(queuedItems[index - 1])
        }
        if index + 1 < queuedItems.count {
            items.append(queuedItems[index + 1])
        }

        return Observable.combineLatest(
            items.map { $0.loadPlayerItem().asObservable() }
        ).map { _ in }
    }
}
