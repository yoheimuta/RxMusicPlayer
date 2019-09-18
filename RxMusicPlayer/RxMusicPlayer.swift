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
        case stop

        public static func == (lhs: Command, rhs: Command) -> Bool {
            switch (lhs, rhs) {
            case (.play, .play),
                 (.next, .next),
                 (.previous, .previous),
                 (.pause, .pause),
                 (.stop, .stop):
                return true
            case let (.playAt(lindex), .playAt(index: rindex)):
                return lindex == rindex
            default:
                return false
            }
        }
    }

    public private(set) var playIndex: Int {
        set {
            playIndexRelay.accept(newValue)
        }
        get {
            return playIndexRelay.value
        }
    }

    public private(set) var queuedItems: [RxMusicPlayerItem] {
        set {
            queuedItemsRelay.accept(newValue)
        }
        get {
            return queuedItemsRelay.value
        }
    }

    public private(set) var status: Status {
        set {
            statusRelay.accept(newValue)
        }
        get {
            return statusRelay.value
        }
    }

    let playIndexRelay = BehaviorRelay<Int>(value: 0)
    let queuedItemsRelay = BehaviorRelay<[RxMusicPlayerItem]>(value: [])
    let statusRelay = BehaviorRelay<Status>(value: .ready)
    let playerRelay = BehaviorRelay<AVPlayer?>(value: nil)

    private let scheduler = ConcurrentDispatchQueueScheduler(
        queue: DispatchQueue.global(qos: .background)
    )
    public private(set) var player: AVPlayer? {
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
        let autoCmd = PublishRelay<Command>()

        let status = statusRelay
            .asObservable()

        let playerStatus = playerRelay
            .flatMapLatest { p -> Observable<()> in
                guard let weakPlayer = p else {
                    return .just(())
                }
                return weakPlayer.rx.status
                    .map { [weak self] st in
                        switch st {
                        case .failed:
                            self?.status = .critical(err: weakPlayer.error!)
                            autoCmd.accept(.stop)
                        default:
                            break
                        }
                    }
            }
            .subscribe()

        let playerItemStatus = playerRelay
            .flatMapLatest { p -> Observable<()> in
                guard let weakItem = p?.currentItem else {
                    return .just(())
                }
                return weakItem.rx.status
                    .map { [weak self] st in
                        switch st {
                        case .readyToPlay: self?.status = .playing
                        case .failed: self?.status = .failed(err: weakItem.error!)
                        default: self?.status = .loading
                        }
                    }
            }
            .subscribe()

        let newErrorLogEntry = NotificationCenter.default.rx
            .notification(.AVPlayerItemNewErrorLogEntry)
            .do(onNext: { [weak self] notification in
                guard let object = notification.object,
                    let playerItem = object as? AVPlayerItem else {
                    return
                }
                guard let errorLog: AVPlayerItemErrorLog = playerItem.errorLog() else {
                    return
                }
                self?.status = .failed(err: RxMusicPlayerError.playerItemError(log: errorLog))
            })
            .subscribe()

        let failedToPlayToEndTime = NotificationCenter.default.rx
            .notification(.AVPlayerItemFailedToPlayToEndTime)
            .do(onNext: { [weak self] notification in
                guard let val = notification.userInfo?["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? String
                else {
                    self?.status = .failed(err: RxMusicPlayerError.internalError(
                        "not found AVPlayerItemFailedToPlayToEndTimeErrorKey"))
                    return
                }
                self?.status = .failed(err: RxMusicPlayerError.failedToPlayToEndTime(val))
            })
            .subscribe()

        let endTime = NotificationCenter.default.rx
            .notification(.AVPlayerItemDidPlayToEndTime)
            .withLatestFrom(rx.canSendCommand(cmd: .next))
            .do(onNext: { isEnabled in
                if isEnabled {
                    autoCmd.accept(.next)
                } else {
                    autoCmd.accept(.stop)
                }
            })
            .subscribe()

        let cmdRunner = Observable.merge(
            cmd.asObservable(),
            autoCmd.asObservable()
        )
        .flatMapLatest(runCommand)
        .subscribe()

        return Observable.create { observer in
            let statusDisposable = status
                .distinctUntilChanged()
                .subscribe(observer)

            return Disposables.create {
                statusDisposable.dispose()
                playerStatus.dispose()
                playerItemStatus.dispose()
                newErrorLogEntry.dispose()
                failedToPlayToEndTime.dispose()
                endTime.dispose()
                cmdRunner.dispose()
            }
        }
        .asDriver(onErrorJustReturn: statusRelay.value)
    }

    private func runCommand(cmd: Command) -> Observable<()> {
        return rx.canSendCommand(cmd: cmd).asObservable().take(1)
            .observeOn(scheduler)
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
                case .stop:
                    return weakSelf.stop()
                }
            }
            .catchError { [weak self] err in
                self?.status = .failed(err: err)
                return .just(())
            }
    }

    private func play() -> Observable<()> {
        return play(atIndex: playIndex)
    }

    private func play(atIndex index: Int) -> Observable<()> {
        if playIndex == index && status == .paused {
            return resume()
        }

        player?.pause()

        playIndex = index
        status = .loading

        return queuedItems[playIndex].loadPlayerItem()
            .asObservable()
            .flatMapLatest { [weak self] item -> Observable<()> in
                guard let weakSelf = self, let weakItem = item else {
                    return .error(RxMusicPlayerError.notFoundWeakReference)
                }
                weakSelf.player = nil

                let player = AVPlayer(playerItem: weakItem.playerItem)
                weakSelf.player = player
                weakSelf.player!.automaticallyWaitsToMinimizeStalling = false
                weakSelf.player!.play()
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
        status = .paused
        return .just(())
    }

    private func resume() -> Observable<()> {
        player?.play()
        status = .playing
        return .just(())
    }

    private func stop() -> Observable<()> {
        player?.pause()
        player = nil

        status = .ready
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
