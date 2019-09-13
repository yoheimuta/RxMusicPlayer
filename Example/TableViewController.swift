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

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let item = RxMusicPlayerItem(url: URL(string:
                "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3")!)
        let player = RxMusicPlayer(items: [item])

        Driver.merge(
            playButton.rx.tap.asDriver().map { RxMusicPlayer.Command.play },
            nextButton.rx.tap.asDriver().map { RxMusicPlayer.Command.next },
            prevButton.rx.tap.asDriver().map { RxMusicPlayer.Command.previous }
        )
        .flatMapLatest({ cmd in
            player.run(cmd: cmd)
        })
        .debug()
        .do(onNext: { status in
            switch status {
            case .ready:
                print("ready to playback")
            case .loading:
                print("loading now")
            case .playing:
                print("playing now")
            case .paused:
                print("pausing now")
            case let .failed(err):
                print("error=\(err)")
            }
        })
        .drive()
        .disposed(by: disposeBag)
    }
}
