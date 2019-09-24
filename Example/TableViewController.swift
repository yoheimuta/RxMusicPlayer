//
//  TableTableViewController.swift
//  Example
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import RxCocoa
import RxMusicPlayer
import RxSwift
import UIKit

class TableViewController: UITableViewController {

    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var prevButton: UIButton!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var seekBar: ProgressSlider!
    @IBOutlet private var seekDurationLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var shuffleButton: UIButton!
    @IBOutlet private var repeatButton: UIButton!

    private let disposeBag = DisposeBag()

    // swiftlint:disable cyclomatic_complexity
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) Create a player
        let items = [
            "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3",
            "https://ccrma.stanford.edu/~jos/mp3/oboe-bassoon.mp3",
            "https://ccrma.stanford.edu/~jos/mp3/shakuhachi.mp3",
            "https://ccrma.stanford.edu/~jos/mp3/trumpet.mp3",
        ]
        .map({ RxMusicPlayerItem(url: URL(string: $0)!) })
        let player = RxMusicPlayer(items: items)!

        // 2) Control views
        player.rx.canSendCommand(cmd: .play)
            .do(onNext: { [weak self] canPlay in
                self?.playButton.setTitle(canPlay ? "Play" : "Pause", for: .normal)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .next)
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .previous)
            .drive(prevButton.rx.isEnabled)
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .seek(seconds: 0, shouldPlay: false))
            .drive(seekBar.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)

        player.rx.currentItemTitle()
            .map { $0 ?? "No Title" }
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        player.rx.currentItemRestDurationDisplay()
            .map {
                guard let rest = $0 else { return "--:--" }
                return "-\(rest)"
            }
            .drive(durationLabel.rx.text)
            .disposed(by: disposeBag)

        player.rx.currentItemTimeDisplay()
            .drive(seekDurationLabel.rx.text)
            .disposed(by: disposeBag)

        player.rx.currentItemDuration()
            .map { Float($0?.seconds ?? 0) }
            .do(onNext: { [weak self] in
                self?.seekBar.maximumValue = $0
            })
            .drive()
            .disposed(by: disposeBag)

        let seekValuePass = BehaviorRelay<Bool>(value: true)
        player.rx.currentItemTime()
            .withLatestFrom(seekValuePass.asDriver()) { ($0, $1) }
            .filter { $0.1 }
            .map { Float($0.0?.seconds ?? 0) }
            .drive(seekBar.rx.value)
            .disposed(by: disposeBag)
        seekBar.rx.controlEvent(.touchDown)
            .do(onNext: {
                seekValuePass.accept(false)
            })
            .subscribe()
            .disposed(by: disposeBag)
        seekBar.rx.controlEvent(.touchUpInside)
            .do(onNext: {
                seekValuePass.accept(true)
            })
            .subscribe()
            .disposed(by: disposeBag)

        player.rx.currentItemLoadedProgressRate()
            .drive(seekBar.rx.playableProgress)
            .disposed(by: disposeBag)

        player.rx.shuffleMode()
            .do(onNext: { [weak self] mode in
                self?.shuffleButton.setTitle(mode == .off ? "Shuffle" : "No Shuffle", for: .normal)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.repeatMode()
            .do(onNext: { [weak self] mode in
                var title = ""
                switch mode {
                case .none: title = "Repeat"
                case .one: title = "Repeat(All)"
                case .all: title = "No Repeat"
                }
                self?.repeatButton.setTitle(title, for: .normal)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.playerIndex()
            .do(onNext: { index in
                if index == player.queuedItems.count - 1 {
                    player.append(items: items)
                }
            })
            .drive()
            .disposed(by: disposeBag)

        // 3) Process the user's input
        let cmd = Driver.merge(
            playButton.rx.tap.asDriver().map { [weak self] in
                if self?.playButton.currentTitle == "Play" {
                    return RxMusicPlayer.Command.play
                }
                return RxMusicPlayer.Command.pause
            },
            nextButton.rx.tap.asDriver().map { RxMusicPlayer.Command.next },
            prevButton.rx.tap.asDriver().map { RxMusicPlayer.Command.previous },
            seekBar.rx.controlEvent(.valueChanged).asDriver()
                .map { [weak self] _ in
                    RxMusicPlayer.Command.seek(seconds: Int(self?.seekBar.value ?? 0),
                                               shouldPlay: false)
                }
                .distinctUntilChanged()
        )
        .debug()

        player.run(cmd: cmd)
            .do(onNext: { status in
                UIApplication.shared.isNetworkActivityIndicatorVisible = status == .loading
            })
            .flatMap { [weak self] status -> Driver<()> in
                guard let weakSelf = self else { return .just(()) }

                switch status {
                case let RxMusicPlayer.Status.failed(err: err):
                    print(err)
                    return Utility.promptOKAlertFor(src: weakSelf,
                                                    title: "Error",
                                                    message: err.localizedDescription)

                case let RxMusicPlayer.Status.critical(err: err):
                    print(err)
                    return Utility.promptOKAlertFor(src: weakSelf,
                                                    title: "Critical Error",
                                                    message: err.localizedDescription)
                default:
                    print(status)
                }
                return .just(())
            }
            .drive()
            .disposed(by: disposeBag)

        shuffleButton.rx.tap.asDriver()
            .drive(onNext: {
                switch player.shuffleMode {
                case .off: player.shuffleMode = .songs
                case .songs: player.shuffleMode = .off
                }
            })
            .disposed(by: disposeBag)

        repeatButton.rx.tap.asDriver()
            .drive(onNext: {
                switch player.repeatMode {
                case .none: player.repeatMode = .one
                case .one: player.repeatMode = .all
                case .all: player.repeatMode = .none
                }
            })
            .disposed(by: disposeBag)
    }
}
