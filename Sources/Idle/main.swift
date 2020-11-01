//
//  main.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/26.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

func main() throws {
  var count = 0
  EventLoop.default.addIdleHandler { idle in
    print("idle")
    if count < 6 {
      count += 1
    } else {
      idle.cancel()
    }
  }
  EventLoop.default.addCheckHandler { check in
    print("check")
    if count < 6 {
      count += 1
    } else {
      check.cancel()
    }
  }
  EventLoop.default.addPrepareHandler { prepare in
    print("prepare")
    if count < 6 {
      count += 1
    } else {
      prepare.cancel()

      EventLoop.default.execute {
        print("Task 3")
      }
    }
  }
  EventLoop.default.execute {
    print("Task 1")
  }
  Thread {
    EventLoop.default.execute {
      print("Task 2")
    }
  }.start()

  try EventLoop.default.run()
  try EventLoop.default.close()
}

do {
  LoggerConfiguration.default.logLevel = .trace
  try main()
} catch {
  print(error)
}
