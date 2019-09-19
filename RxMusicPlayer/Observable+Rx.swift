//
//  Observable+Rx.swift
//  RxMusicPlayer
//
//  Created by YOSHIMUTA YOHEI on 2019/09/19.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import RxSwift

extension ObservableType {

    func withPrevious() -> Observable<(previous: Element?, current: Element)> {
        return scan([], accumulator: { previous, current in
            Array(previous + [current]).suffix(2)
        })
            .map({ (arr) -> (previous: Element?, current: Element) in
                (arr.count > 1 ? arr.first : nil, arr.last!)
            })
} }
