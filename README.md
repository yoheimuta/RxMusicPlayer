# RxMusicPlayer

[![Build Status](https://app.bitrise.io/app/24b27b1bde763767/status.svg?token=i0LQTpCPw6Sm_mObo3YqTw&branch=master)](https://app.bitrise.io/app/24b27b1bde763767)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/RxMusicPlayer.svg?style=flat)](http://cocoapods.org/pods/RxMusicPlayer)
[![License](https://img.shields.io/cocoapods/l/RxMusicPlayer.svg?style=flat)](http://cocoapods.org/pods/RxMusicPlayer)

RxMusicPlayer is a wrapper of avplayer backed by RxSwift to make it easy for audio playbacks.

## Features

- Following [the Audio Guidelines for User-Controlled Playback and Recording Apps](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioGuidelinesByAppType/AudioGuidelinesByAppType.html#//apple_ref/doc/uid/TP40007875-CH11-SW1).
- Support for streaming both remote and local audio files.
- Functions to `play`, `pause`, `stop`, `play next`, `play previous`, `prefetch metadata`, `repeat mode(repeat, repeat all)`, `shuffle mode` `desired playback rate` and `seek to a certain second`.
- Loading metadata, including `title`, `album`, `artist`, `artwork`, `duration`, and `lyrics`.
- Background mode integration with MPNowPlayingInfoCenter.
- Remote command control integration with MPRemoteCommandCenter.
- Interruption handling with AVAudioSession.interruptionNotification.
- Route change handling with AVAudioSession.routeChangeNotification.
- Including a fully working example project.

## Runtime Requirements

- iOS 10.0 or later

## Installation

### Carthage

```
github "yoheimuta/RxMusicPlayer"
```

### CocoaPods

```
pod "RxMusicPlayer"
```

## Usage

For details, refer to the [Example project](https://github.com/yoheimuta/RxMusicPlayer/tree/master/Example).
Plus, see also **Users** section below.

### Example

<img src="doc/example.gif" alt="example" width="300"/>

You can implement your audio player with the custom frontend without any delegates, like below.

```swift
import RxCocoa
import RxMusicPlayer
import RxSwift
import UIKit

class TableViewController: UITableViewController {

    @IBOutlet private var playButton: UIButton!
    @IBOutlet private var nextButton: UIButton!
    @IBOutlet private var prevButton: UIButton!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var artImageView: UIImageView!
    @IBOutlet private var lyricsLabel: UILabel!
    @IBOutlet private var seekBar: ProgressSlider!
    @IBOutlet private var seekDurationLabel: UILabel!
    @IBOutlet private var durationLabel: UILabel!
    @IBOutlet private var shuffleButton: UIButton!
    @IBOutlet private var repeatButton: UIButton!
    @IBOutlet private var rateButton: UIButton!

    private let disposeBag = DisposeBag()

    // swiftlint:disable cyclomatic_complexity
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) Create a player
        let items = [
            "https://storage.googleapis.com/maison-great-dev/oss/musicplayer/tagmp3_1473200_1.mp3",
            "https://storage.googleapis.com/maison-great-dev/oss/musicplayer/tagmp3_2160166.mp3",
            "https://storage.googleapis.com/maison-great-dev/oss/musicplayer/tagmp3_4690995.mp3",
            "https://storage.googleapis.com/maison-great-dev/oss/musicplayer/tagmp3_9179181.mp3",
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
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)

        player.rx.currentItemArtwork()
            .drive(artImageView.rx.image)
            .disposed(by: disposeBag)

        player.rx.currentItemLyrics()
            .distinctUntilChanged()
            .do(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .drive(lyricsLabel.rx.text)
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
                    // You can remove the comment-out below to confirm the append().
                    // player.append(items: items)
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
        .startWith(.prefetch)
        .debug()

        // You can remove the comment-out below to confirm changing the current index of music items.
        // Default is 0.
        // player.playIndex = 1

        player.run(cmd: cmd)
            .do(onNext: { status in
                UIApplication.shared.isNetworkActivityIndicatorVisible = status == .loading
            })
            .flatMap { [weak self] status -> Driver<()> in
                guard let weakSelf = self else { return .just(()) }

                switch status {
                case let RxMusicPlayer.Status.failed(err: err):
                    print(err)
                    return Wireframe.promptOKAlertFor(src: weakSelf,
                                                      title: "Error",
                                                      message: err.localizedDescription)

                case let RxMusicPlayer.Status.critical(err: err):
                    print(err)
                    return Wireframe.promptOKAlertFor(src: weakSelf,
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

        rateButton.rx.tap.asDriver()
            .flatMapLatest { [weak self] _ -> Driver<()> in
                guard let weakSelf = self else { return .just(()) }

                return Wireframe.promptSimpleActionSheetFor(
                    src: weakSelf,
                    cancelAction: "Close",
                    actions: PlaybackRateAction.allCases.map {
                        player.desiredPlaybackRate == $0.toFloat ? "\($0.rawValue)✓" : $0.rawValue
                })
                    .do(onNext: { [weak self] action in
                        if let rate = PlaybackRateAction(rawValue: action)?.toFloat {
                            player.desiredPlaybackRate = rate
                            self?.rateButton.setTitle(action, for: .normal)
                        }
                    })
                    .map { _ in }
            }
            .drive()
            .disposed(by: disposeBag)
    }
}
```

## Users

- AMMusicPlayerController
  - https://github.com/yoheimuta/AMMusicPlayerController

## Contributing

- Fork it
- Run `make bootstrap`
- Create your feature branch: git checkout -b your-new-feature
- Commit changes: git commit -m 'Add your feature'
- Push to the branch: git push origin your-new-feature
- Submit a pull request

## Bug Report

While any bug reports are helpful, it's sometimes unable to pinpoint the cause without a reproducible project.

In particular, since RxMusicPlayer depends on RxSwift that is prone to your application program mistakes, it's more essential to decouple the problem.

Therefore, I highly recommend that you submit an issue with that project.

You can create it like the following steps.

- Fork it
- Create your feature branch: git checkout -b your-bug-name
- Add some changes under the Example directory to reproduce the bug
- Commit changes: git commit -m 'Add a reproducible feature'
- Push to the branch: git push origin your-bug-name
- (Optional) Submit a pull request
- Share it in your issue

The code should not be intertwined but concise, straightforward, and naive.

NOTE: If you can't prepare any reproducible code, you have to elaborate the detail precisely and clearly so that I can reproduce the problem.

## License

The MIT License (MIT)

## Acknowledgement

Thank you to the following projects and creators.

- Jukebox: https://github.com/teodorpatras/Jukebox
  - I inspired by this library for the interface and some implementation.
- RxAudioVisual: https://github.com/keitaoouchi/RxAudioVisual
  - I referred to some implementation instead of depending on it due to adaptation to the latest Swift compiler.
- Smith, J.O. Physical Audio Signal Processing: https://ccrma.stanford.edu/~jos/waveguide/Sound_Examples.html
  - This project is using these as sample mp3 files.
- file-examples.com: https://file-examples.com/index.php/sample-audio-files/sample-mp3-download/
  - This project is using one as a sample mp3 file.
