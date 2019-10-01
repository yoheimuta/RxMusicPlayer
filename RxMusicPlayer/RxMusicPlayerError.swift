//
//  RxMusicPlayerError.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import AVFoundation
import Foundation

public enum RxMusicPlayerError: Error, Equatable {
    // Indicates an internal error. This implies a library bug.
    case internalError(String)
    // Indicates an invalid weak reference. This implies a library bug.
    case notFoundWeakReference
    // Indicates a given command is invalid.
    case invalidCommand(cmd: RxMusicPlayer.Command)
    // Indicates a failure happended during the loading of a metadata.
    case playerItemMetadataFailed(err: Error)
    // Indicates a failure happended during the loading of an item.
    case playerItemFailed(err: Error)
    // Indicates an AVPlayerItemNewErrorLogEntry.
    case playerItemError(log: AVPlayerItemErrorLog)
    // Indicates an AVPlayerItemFailedToPlayToEndTimeError.
    case failedToPlayToEndTime(String)

    public static func == (lhs: RxMusicPlayerError, rhs: RxMusicPlayerError) -> Bool {
        switch (lhs, rhs) {
        case (.internalError, .internalError),
             (.notFoundWeakReference, .notFoundWeakReference):
            return true
        case let (.invalidCommand(cmd: lcmd), .invalidCommand(cmd: rcmd)):
            return lcmd == rcmd
        default:
            return false
        }
    }
}
