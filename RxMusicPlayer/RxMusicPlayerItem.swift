//
//  RxMusicPlayerItem.swift
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

open class RxMusicPlayerItem: NSObject {
    /**
     Metadata for player item.
     */
    public struct Meta {
        public fileprivate(set) var duration: CMTime?
        public private(set) var title: String?
        public private(set) var album: String?
        public private(set) var artist: String?
        public private(set) var artwork: UIImage?

        let didAllSetRelay = BehaviorRelay<Bool>(value: false)

        fileprivate mutating func set(metaItem item: AVMetadataItem) {
            guard let commonKey = item.commonKey else { return }

            switch commonKey.rawValue {
            case "title": title = item.value as? String
            case "albumName": album = item.value as? String
            case "artist": artist = item.value as? String
            case "artwork": processArtwork(fromMetadataItem: item)
            default: break
            }
        }

        private mutating func processArtwork(fromMetadataItem item: AVMetadataItem) {
            guard let value = item.value else { return }
            let copiedValue: AnyObject = value.copy(with: nil) as AnyObject

            if let dict = copiedValue as? [AnyHashable: Any] {
                // AVMetadataKeySpaceID3
                if let imageData = dict["data"] as? Data {
                    artwork = UIImage(data: imageData)
                }
            } else if let data = copiedValue as? Data {
                // AVMetadataKeySpaceiTunes
                artwork = UIImage(data: data)
            }
        }
    }

    let url: Foundation.URL

    fileprivate(set) var meta: Meta = Meta()
    fileprivate(set) var playerItem: AVPlayerItem?

    /**
     Create an instance with an URL and local title

     - parameter url: local or remote URL of the audio file

     - returns: RxMusicPlayerItem instance
     */
    public required init(url: Foundation.URL) {
        self.url = url
        super.init()
    }

    func loadPlayerItem() -> Single<RxMusicPlayerItem?> {
        if meta.didAllSetRelay.value {
            playerItem = AVPlayerItem(asset: playerItem!.asset)
            return .just(self)
        }

        let asset = AVAsset(url: url)

        return Single.create { single in
            let load = Observable.combineLatest(
                Observable.combineLatest(
                    asset.commonMetadata
                        .map { m in
                            m.rx.loadAsync(for: AVMetadataKeySpace.common.rawValue)
                                .map { _ in m }
                                .asObservable()
                        }
                )
                .map { [weak self] ms in
                    for m in ms {
                        self?.meta.set(metaItem: m)
                    }
                    return
                },
                asset.rx.duration
                    .asObservable()
                    .map { [weak self] duration in
                        self?.meta.duration = duration
                        return
                    }
            )
            .map { [weak self] _ in
                self?.meta.didAllSetRelay.accept(true)
                self?.playerItem = AVPlayerItem(asset: asset)
                single(.success(self))
            }
            .subscribe()

            return Disposables.create {
                load.dispose()
            }
        }
    }
}
