//
//  RxMusicPlayerError.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

public enum RxMusicPlayerError: Error, Equatable {
    case internalError
    case notFoundWeakReference
    case invalidCommand(cmd: RxMusicPlayer.Command)

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
