# RxMusicPlayer

[![Build Status](https://app.bitrise.io/app/24b27b1bde763767/status.svg?token=i0LQTpCPw6Sm_mObo3YqTw&branch=master)](https://app.bitrise.io/app/24b27b1bde763767)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
<a href="https://github.com/apple/swift-package-manager" alt="RxMusicPlayer on Swift Package Manager" title="RxMusicPlayer on Swift Package Manager"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg" /></a>
[![Version](https://img.shields.io/cocoapods/v/RxMusicPlayer.svg?style=flat)](http://cocoapods.org/pods/RxMusicPlayer)
[![License](https://img.shields.io/cocoapods/l/RxMusicPlayer.svg?style=flat)](http://cocoapods.org/pods/RxMusicPlayer)

RxMusicPlayer is a wrapper of avplayer backed by RxSwift to make it easy for audio playbacks.

## Features

- Following [the Audio Guidelines for User-Controlled Playback and Recording Apps](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/AudioGuidelinesByAppType/AudioGuidelinesByAppType.html#//apple_ref/doc/uid/TP40007875-CH11-SW1).
- Support for streaming both remote and local audio files.
- Functions to `play`, `pause`, `stop`, `play next`, `play previous`, `skip forward/backward`, `prefetch metadata`, `repeat mode(repeat, repeat all)`, `shuffle mode` `desired playback rate`, `seek to a certain second`, and `append/insert/remove an item into the playlist`.
- Loading metadata, including `title`, `album`, `artist`, `artwork`, `duration`, and `lyrics`.
- Background mode integration with MPNowPlayingInfoCenter.
- Remote command control integration with MPRemoteCommandCenter.
- Interruption handling with AVAudioSession.interruptionNotification.
- Route change handling with AVAudioSession.routeChangeNotification.
- Including a fully working example project, one built on UIKit and the other built on SwiftUI.

## Runtime Requirements

- iOS 10.0 or later

## Installation

### Swift Package Manager

With 2.0.1 and above.

### Carthage

```
github "yoheimuta/RxMusicPlayer"
```

### CocoaPods

```
pod "RxMusicPlayer"
```

## Usage

For details, refer to the [ExampleSwiftUI project](https://github.com/yoheimuta/RxMusicPlayer/tree/master/ExampleSwiftUI) or [Example project](https://github.com/yoheimuta/RxMusicPlayer/tree/master/Example).
Plus, see also **Users** section below.

## Example

<img src="doc/example.gif" alt="example" width="300"/>

You can implement your audio player with the custom frontend without any delegates, like below.

### Based on SwiftUI

```swift
import SwiftUI
import Combine
import RxMusicPlayer
import RxSwift
import RxCocoa

final class PlayerModel: ObservableObject {
    private let disposeBag = DisposeBag()
    private let player: RxMusicPlayer
    private let commandRelay = PublishRelay<RxMusicPlayer.Command>()

    @Published var canPlay = true
    @Published var canPlayNext = true
    @Published var canPlayPrevious = true
    @Published var canSkipForward = true
    @Published var canSkipBackward = true
    @Published var title = "Not Playing"
    @Published var artwork: UIImage?
    @Published var restDuration = "--:--"
    @Published var duration = "--:--"
    @Published var shuffleMode = RxMusicPlayer.ShuffleMode.off
    @Published var repeatMode = RxMusicPlayer.RepeatMode.none
    @Published var remoteControl = RxMusicPlayer.RemoteControl.moveTrack

    @Published var sliderValue = Float(0)
    @Published var sliderMaximumValue = Float(0)
    @Published var sliderIsUserInteractionEnabled = false
    @Published var sliderPlayableProgress = Float(0)

    private var cancelBag = Set<AnyCancellable>()
    var sliderValueChanged = PassthroughSubject<Float, Never>()

    init() {
        // 1) Create a player
        let items = [
            URL(string: "https://storage.googleapis.com/great-dev/oss/musicplayer/tagmp3_1473200_1.mp3")!,
            URL(string: "https://storage.googleapis.com/great-dev/oss/musicplayer/tagmp3_2160166.mp3")!,
            URL(string: "https://storage.googleapis.com/great-dev/oss/musicplayer/tagmp3_4690995.mp3")!,
            Bundle.main.url(forResource: "tagmp3_9179181", withExtension: "mp3")!
        ]
        .map({ RxMusicPlayerItem(url: $0) })
        player = RxMusicPlayer(items: items)!

        // 2) Control views
        player.rx.canSendCommand(cmd: .play)
            .do(onNext: { [weak self] canPlay in
                self?.canPlay = canPlay
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .next)
            .do(onNext: { [weak self] canPlayNext in
                self?.canPlayNext = canPlayNext
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .previous)
            .do(onNext: { [weak self] canPlayPrevious in
                self?.canPlayPrevious = canPlayPrevious
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .seek(seconds: 0, shouldPlay: false))
            .do(onNext: { [weak self] canSeek in
                self?.sliderIsUserInteractionEnabled = canSeek
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .skip(seconds: 15))
            .do(onNext: { [weak self] canSkip in
                self?.canSkipForward = canSkip
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.canSendCommand(cmd: .skip(seconds: -15))
            .do(onNext: { [weak self] canSkip in
                self?.canSkipBackward = canSkip
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemDuration()
            .do(onNext: { [weak self] in
                self?.sliderMaximumValue = Float($0?.seconds ?? 0)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemTime()
            .do(onNext: { [weak self] time in
                self?.sliderValue = Float(time?.seconds ?? 0)
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemLoadedProgressRate()
            .do(onNext: { [weak self] rate in
                self?.sliderPlayableProgress = rate ?? 0
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemTitle()
            .do(onNext: { [weak self] title in
                self?.title = title ?? ""
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemArtwork()
            .do(onNext: { [weak self] artwork in
                self?.artwork = artwork
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemRestDurationDisplay()
            .do(onNext: { [weak self] duration in
                self?.restDuration = duration ?? "--:--"
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.currentItemTimeDisplay()
            .do(onNext: { [weak self] duration in
                if duration == "00:00" {
                    self?.duration = "0:00"
                    return
                }
                self?.duration = duration ?? "--:--"
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.shuffleMode()
            .do(onNext: { [weak self] mode in
                self?.shuffleMode = mode
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.repeatMode()
            .do(onNext: { [weak self] mode in
                self?.repeatMode = mode
            })
            .drive()
            .disposed(by: disposeBag)

        player.rx.remoteControl()
            .do(onNext: { [weak self] control in
                self?.remoteControl = control
            })
            .drive()
            .disposed(by: disposeBag)

        // 3) Process the user's input
        player.run(cmd: commandRelay.asDriver(onErrorDriveWith: .empty()))
            .flatMap { status -> Driver<()> in
                switch status {
                case let RxMusicPlayer.Status.failed(err: err):
                    print(err)
                case let RxMusicPlayer.Status.critical(err: err):
                    print(err)
                default:
                    print(status)
                }
                return .just(())
            }
            .drive()
            .disposed(by: disposeBag)

        commandRelay.accept(.prefetch)

        sliderValueChanged
            .removeDuplicates()
            .sink { [weak self] value in
                self?.seek(value: value)
            }
            .store(in: &cancelBag)
    }

    func seek(value: Float?) {
        commandRelay.accept(.seek(seconds: Int(value ?? 0), shouldPlay: false))
    }

    func skip(second: Int) {
        commandRelay.accept(.skip(seconds: second))
    }

    func shuffle() {
        switch player.shuffleMode {
        case .off: player.shuffleMode = .songs
        case .songs: player.shuffleMode = .off
        }
    }

    func play() {
        commandRelay.accept(.play)
    }

    func pause() {
        commandRelay.accept(.pause)
    }

    func playNext() {
        commandRelay.accept(.next)
    }

    func playPrevious() {
        commandRelay.accept(.previous)
    }

    func doRepeat() {
        switch player.repeatMode {
        case .none: player.repeatMode = .one
        case .one: player.repeatMode = .all
        case .all: player.repeatMode = .none
        }
    }

    func toggleRemoteControl() {
        switch remoteControl {
        case .moveTrack:
            player.remoteControl = .skip(second: 15)
        case .skip:
            player.remoteControl = .moveTrack
        }
    }
}

struct PlayerView: View {
    @StateObject private var model = PlayerModel()

    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                    .frame(width: 1, height: 49)

                if let artwork = model.artwork {
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 276)
                } else {
                    Spacer()
                        .frame(width: 1, height: 276)
                }

                ProgressSliderView(value: $model.sliderValue,
                                   maximumValue: $model.sliderMaximumValue,
                                   isUserInteractionEnabled: $model.sliderIsUserInteractionEnabled,
                                   playableProgress: $model.sliderPlayableProgress) {
                    model.sliderValueChanged.send($0)
                }
                    .padding(.horizontal)

                HStack {
                    Text(model.duration)
                    Spacer()
                    Text(model.restDuration)
                }
                .padding(.horizontal)

                Spacer()
                    .frame(width: 1, height: 17)

                Text(model.title)

                Spacer()
                    .frame(width: 1, height: 19)

                HStack(spacing: 20.0) {
                    Button(action: {
                        model.shuffle()
                    }) {
                        Text(model.shuffleMode == .off ? "Shuffle" : "No Shuffle")
                    }

                    Button(action: {
                        model.playPrevious()
                    }) {
                        Text("Previous")
                    }
                    .disabled(!model.canPlayPrevious)

                    Button(action: {
                        model.canPlay ? model.play() : model.pause()
                    }) {
                        Text(model.canPlay ? "Play" : "Pause")
                    }

                    Button(action: {
                        model.playNext()
                    }) {
                        Text("Next")
                    }
                    .disabled(!model.canPlayNext)

                    Button(action: {
                        model.doRepeat()
                    }) {
                        Text({
                            switch model.repeatMode {
                            case .none: return "Repeat"
                            case .one: return "Repeat(All)"
                            case .all: return "No Repeat"
                            }
                        }() as String)
                    }
                }

                Group {
                    Spacer()
                        .frame(width: 1, height: 17)

                    HStack(spacing: 20.0) {
                        Button(action: {
                            model.skip(second: -15)
                        }) {
                            Text("SkipBackward")
                        }
                        .disabled(!model.canSkipBackward)

                        Button(action: {
                            model.skip(second: 15)
                        }) {
                            Text("SkipForward")
                        }
                        .disabled(!model.canSkipForward)
                    }
                }

                Group {
                    Spacer()
                        .frame(width: 1, height: 17)

                    HStack(spacing: 20.0) {
                        Button(action: {
                            model.toggleRemoteControl()
                        }) {
                            let control = model.remoteControl == .moveTrack ? "moveTrack" : "skip"
                            Text("RemoteControl: \(control)")
                        }
                    }
                }
            }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
```

### Based on UIKit

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
    @IBOutlet private var appendButton: UIButton!
    @IBOutlet private var changeButton: UIButton!

    private let disposeBag = DisposeBag()

    // swiftlint:disable cyclomatic_complexity
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) Create a player
        let items = [
            "https://storage.googleapis.com/great-dev/oss/musicplayer/tagmp3_1473200_1.mp3",
            "https://storage.googleapis.com/great-dev/oss/musicplayer/tagmp3_2160166.mp3",
            "https://storage.googleapis.com/great-dev/oss/musicplayer/tagmp3_4690995.mp3",
            "https://storage.googleapis.com/great-dev/oss/musicplayer/tagmp3_9179181.mp3",
            "https://storage.googleapis.com/great-dev/oss/musicplayer/bensound-extremeaction.mp3",
            "https://storage.googleapis.com/great-dev/oss/musicplayer/bensound-littleplanet.mp3",
        ]
        .map({ RxMusicPlayerItem(url: URL(string: $0)!) })
        let player = RxMusicPlayer(items: Array(items[0 ..< 4]))!

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
                        ($0.rawValue, player.desiredPlaybackRate == $0.toFloat)
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

        appendButton.rx.tap.asDriver()
            .do(onNext: {
                let newItems = Array(items[4 ..< 6])
                player.append(items: newItems)
            })
            .drive(onNext: { [weak self] _ in
                self?.appendButton.isEnabled = false
            })
            .disposed(by: disposeBag)

        changeButton.rx.tap.asObservable()
            .flatMapLatest { [weak self] _ -> Driver<()> in
                guard let weakSelf = self else { return .just(()) }

                return Wireframe.promptSimpleActionSheetFor(
                    src: weakSelf,
                    cancelAction: "Close",
                    actions: items.map {
                        ($0.url.lastPathComponent, player.queuedItems.contains($0))
                })
                    .asObservable()
                    .do(onNext: { action in
                        if let idx = player.queuedItems.map({ $0.url.lastPathComponent }).firstIndex(of: action) {
                            try player.remove(at: idx)
                        } else if let idx = items.map({ $0.url.lastPathComponent }).firstIndex(of: action) {
                            for i in (0 ... idx).reversed() {
                                if let prev = player.queuedItems.firstIndex(of: items[i]) {
                                    player.insert(items[idx], at: prev + 1)
                                    break
                                }
                                if i == 0 {
                                    player.insert(items[idx], at: 0)
                                }
                            }
                        }

                        self?.appendButton.isEnabled = !(player.queuedItems.contains(items[4])
                            || player.queuedItems.contains(items[5]))
                    })
                    .asDriver(onErrorJustReturn: "")
                    .map { _ in }
            }
            .asDriver(onErrorJustReturn: ())
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

### Release

- Create a new release on GitHub
- Publish a new podspec on Cocoapods
  - `bundle exec pod trunk push RxMusicPlayer.podspec`

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
