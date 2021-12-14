//
//  RxMusicPlayerTests.swift
//  RxMusicPlayerTests
//
//  Created by YOSHIMUTA YOHEI on 2019/09/12.
//  Copyright © 2019 YOSHIMUTA YOHEI. All rights reserved.
//

import XCTest
import AVFoundation
@testable import RxMusicPlayer

class RxMusicPlayerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCMTime_displayName() {
        XCTAssertEqual(CMTimeMake(value: 1, timescale: 1).displayTime, "00:01", "convert an integer second")
        XCTAssertEqual(CMTimeMake(value: 1, timescale: 10).displayTime, "00:00", "convert a non-integer second near 0")
        XCTAssertEqual(CMTimeMake(value: 6, timescale: 10).displayTime, "00:01", "convert a non-integer second near 1")
        XCTAssertEqual(CMTimeMake(value: 60, timescale: 1).displayTime, "01:00", "convert a minute")
        XCTAssertEqual(CMTimeMake(value: 601, timescale: 1).displayTime, "10:01", "convert ten minutes")
        XCTAssertEqual(CMTimeMake(value: 3600, timescale: 1).displayTime, "01:00:00", "convert an hour")
        XCTAssertEqual(CMTimeMake(value: 86400, timescale: 1).displayTime, "24:00:00", "convert a day")
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
