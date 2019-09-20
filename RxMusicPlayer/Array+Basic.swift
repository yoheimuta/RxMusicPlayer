//
//  Array+Basic.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/20.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

extension Array {
    func shuffledAround(index: Int) -> [Element] {
        var rest = enumerated()
            .filter { $0.offset != index }
            .map { $0.element }
            .shuffled()
        rest.insert(self[index], at: index)
        return rest
    }
}
