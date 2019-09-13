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
        case failed(err: Error)
    }

    /**
     Player Command.
     */
    public enum Command {
        case play
        case playAt(index: Int)
        case next
        case previous
    }

    private let scheduler = ConcurrentDispatchQueueScheduler(
        queue: DispatchQueue(label: "com.github.yoheimuta.RxMusicPlayer.RxMusicPlayer",
                             qos: .background)
    )
    private var player: AVPlayer?
    private var queuedItems: [RxMusicPlayerItem]
    private var playIndex = 0
    private var status = Status.ready

    /**
     Create an instance with a list of items without loading their assets.

     - parameter items: array of items to be added to the play queue

     - returns: RxMusicPlayer instance
     */
    public required init(items: [RxMusicPlayerItem] = [RxMusicPlayerItem]()) {
        queuedItems = items
    }

    /**
     Run a commmand.
     */
    public func run(cmd: Command) -> Driver<Status> {
        return { () -> Observable<RxMusicPlayer.Status> in
            switch cmd {
            case .play:
                return play()
            case let .playAt(index: index):
                return play(atIndex: index)
            case .next:
                return playNext()
            case .previous:
                return playPrevious()
            }
        }()
            .asDriver(onErrorRecover: { e in .just(Status.failed(err: e)) })
            .do(onNext: { [weak self] in self?.status = $0 })
    }

    private func play() -> Observable<Status> {
        return play(atIndex: playIndex)
    }

    private func play(atIndex index: Int) -> Observable<Status> {
        playIndex = index

        player?.pause()
        return queuedItems[playIndex].loadPlayerItem()
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
            })
    }

    private func playNext() -> Observable<Status> {
        return play(atIndex: playIndex + 1)
    }

    private func playPrevious() -> Observable<Status> {
        return play(atIndex: playIndex - 1)
    }
}
