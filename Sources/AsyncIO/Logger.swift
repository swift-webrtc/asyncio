//
//  Logger.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/28.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Core
import Logging

internal let logger: Logger = {
  var l = Logger(label: "swift-webrtc.asyncio")
  l.logLevel = LoggerConfiguration.default.logLevel
  return l
}()
