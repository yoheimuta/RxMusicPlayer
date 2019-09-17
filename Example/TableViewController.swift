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

    private let disposeBag = DisposeBag()

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
        let player = RxMusicPlayer(items: items)

        // 2) Control views
        player.rx.canSendCommand(cmd: RxMusicPlayer.Command.play)
            .do(onNext: { [weak self] canPlay in
                self?.playButton.setTitle(canPlay ? "Play" : "Pause", for: .normal)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: RxMusicPlayer.Command.next)
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: RxMusicPlayer.Command.previous)
            .drive(prevButton.rx.isEnabled)
            .disposed(by: disposeBag)

        player.rx.currentItemTitle()
            .map { $0 ?? "No Title" }
            .drive(titleLabel.rx.text)
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
            prevButton.rx.tap.asDriver().map { RxMusicPlayer.Command.previous }
        )
        .debug()

        player.loop(cmd: cmd)
            .debug()
            .flatMap { [weak self] status -> Driver<()> in
                guard let weakSelf = self else { return .just(()) }

                switch status {
                case let RxMusicPlayer.Status.failed(err: err):
                    return Utility.promptOKAlertFor(src: weakSelf,
                                                    title: "Error",
                                                    message: err.localizedDescription)

                case let RxMusicPlayer.Status.critical(err: err):
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
    }
}
