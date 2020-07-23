//
//  RxMusicPlayerItem.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import Foundation
import RxCocoa
import RxSwift

open class RxMusicPlayerItem: NSObject {
    /**
     Metadata for player item.
     */
    public struct Meta {
        public fileprivate(set) var duration: CMTime?
        public fileprivate(set) var lyrics: String?
        public private(set) var title: String?
        public private(set) var album: String?
        public private(set) var artist: String?
        public private(set) var artwork: UIImage?

        let didAllSetRelay = BehaviorRelay<Bool>(value: false)

        /**
         Initialize Metadata with a prefetched one.
         If one of the arguments is not nil, the player will skip downloading the metadata.
         */
        public init(duration: CMTime? = nil,
                    lyrics: String? = nil,
                    title: String? = nil,
                    album: String? = nil,
                    artist: String? = nil,
                    artwork: UIImage? = nil) {
            self.duration = duration
            self.lyrics = lyrics
            self.title = title
            self.album = album
            self.artist = artist
            self.artwork = artwork

            if duration != nil || lyrics != nil || title != nil ||
                album != nil || artist != nil || artist != nil {
                didAllSetRelay.accept(true)
            }
        }

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

    fileprivate(set) var meta: Meta
    fileprivate(set) var playerItem: AVPlayerItem?

    /**
     Create an instance with an URL and local title

     - parameter url: local or remote URL of the audio file
     - parameter meta: prefetched metadata of the audio

     - returns: RxMusicPlayerItem instance
     */
    public required init(url: Foundation.URL, meta: Meta = Meta()) {
        self.meta = meta
        self.url = url
        super.init()
    }

    func loadPlayerItem() -> Single<RxMusicPlayerItem?> {
        if meta.didAllSetRelay.value {
            playerItem = AVPlayerItem(asset: playerItem?.asset ?? AVAsset(url: url))
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
                    },
                asset.rx.loadAsync(for: "lyrics")
                    .map { [weak self] _ in
                        self?.meta.lyrics = asset.lyrics
                        return
                    }
                    .asObservable()
            )
            .map { [weak self] _ in
                self?.meta.didAllSetRelay.accept(true)
                self?.playerItem = AVPlayerItem(asset: asset)
                single(.success(self))
            }
            .subscribe(onError: { err in
                single(.error(RxMusicPlayerError.playerItemMetadataFailed(err: err)))
            })

            return Disposables.create {
                load.dispose()
            }
        }
    }
}
