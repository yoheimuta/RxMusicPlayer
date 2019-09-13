//
//  RxMusicPlayerError.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

public enum RxMusicPlayerError: Error {
    case notFoundWeakReference
    case invalidCommand(cmd: RxMusicPlayer.Command)
}
