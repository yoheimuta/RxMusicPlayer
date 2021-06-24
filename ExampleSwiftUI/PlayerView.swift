//
//  PlayerView.swift
//  ExampleSwiftUI
//
//  Created by Yoheimuta on 2021/06/18.
//  Copyright © 2021 YOSHIMUTA YOHEI. All rights reserved.
//
// swiftlint:disable multiple_closures_with_trailing_closure

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
    @Published var title = "Not Playing"
    @Published var artwork: UIImage?
    @Published var restDuration = "--:--"
    @Published var duration = "--:--"
    @Published var shuffleMode = RxMusicPlayer.ShuffleMode.off
    @Published var repeatMode = RxMusicPlayer.RepeatMode.none

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
            }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
