//
//  Timer.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/22.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv
import Core

internal final class Timer: Cancellable {
  internal let handle: Handle<uv_timer_t>
  internal var handler: Handler<Timer>?

  internal init(eventLoop: EventLoop, handler: @escaping Handler<Timer>) {
    self.handle = Handle(eventLoop: eventLoop, initFn: uv_timer_init)
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
    self.handler = handler
  }

  internal func start(delay: Duration, interval: Duration) {
    uv_timer_start(handle.unsafe, {
      let timer = Unmanaged<Timer>.fromOpaque($0!.pointee.data).takeUnretainedValue()
      timer.handler?(timer)

      if !timer.handle.isClosing && uv_timer_get_repeat(timer.handle.unsafe) == 0 {
        timer.cancel()
      }
    },
    UInt64(delay.milliseconds), UInt64(interval.milliseconds))
  }

  internal func close() {
    handle.close {
      let timer = Unmanaged<Timer>.fromOpaque($0!.pointee.data).takeRetainedValue()
      timer.handler = nil
    }
  }

  internal func cancel() {
    close()
  }
}

// MARK: - EventLoop

extension EventLoop {

  @discardableResult
  public func schedule(
    delay: Duration,
    interval: Duration = .init(nanoseconds: 0),
    handler: @escaping Handler<Cancellable>
  ) -> Cancellable {
    let timer = Timer(eventLoop: self, handler: handler)
    timer.start(delay: delay, interval: interval)
    return timer
  }
}
