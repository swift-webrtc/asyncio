//
//  main.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/24.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

func main() throws {
  var count = 0
  EventLoop.default.schedule(delay: .seconds(0), interval: .seconds(1)) { timer in
    print("Tick")
    if count < 6 {
      count += 1
    } else {
      timer.cancel()
    }
  }

  let thread = Thread {
    print("Thread beigin")
    let loop = EventLoop()
    loop.schedule(delay: .seconds(3)) { timer in
      print("Timer task beigin")
      timer.cancel()
      print("Timer task finished")
    }
    try? loop.run()
    try? loop.close()
    print("Thread finished")
  }
  thread.start()
  thread.join()

  try EventLoop.default.run()
  try EventLoop.default.close()
}

do {
  LoggerConfiguration.default.logLevel = .trace
  try main()
} catch {
  print(error)
}
