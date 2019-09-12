//
//  TableTableViewController.swift
//  Example
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import RxMusicPlayer
import RxSwift
import UIKit

class TableViewController: UITableViewController {

    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var prevButton: UIButton!

    private var player: RxMusicPlayer!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        let item = RxMusicPlayerItem(url: URL(string:
                "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3")!)
        player = RxMusicPlayer(items: [item])
        player.rx.status
            .debug()
            .drive()
            .disposed(by: disposeBag)
        play()
    }

    func play() {
        player.play()
            .do(onError: { error in
                print(error)
            })
            .debug()
            .subscribe()
            .disposed(by: disposeBag)
    }
}
