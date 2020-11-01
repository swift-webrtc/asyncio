//
//  LinuxMain.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/22.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIOTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += SocketAddressTests.allTests
tests += IPAddressTests.allTests
XCTMain(tests)
