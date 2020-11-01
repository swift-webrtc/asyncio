//
//  Task.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/27.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

internal final class Task: Cancellable {
  internal let handle: Handle<uv_async_t>
  internal var handler: Handler<Void>?

  internal init(eventLoop: EventLoop, handler: @escaping Handler<Void>) {
    self.handle = Handle(eventLoop: eventLoop) {
      uv_async_init($0, $1) {
        let task = Unmanaged<Task>.fromOpaque($0!.pointee.data).takeUnretainedValue()
        task.handler?(())
        task.cancel()
      }
    }
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
    self.handler = handler
  }

  internal func start() {
    uv_async_send(handle.unsafe)
  }

  internal func cancel() {
    handle.close {
      let idle = Unmanaged<Prepare>.fromOpaque($0!.pointee.data).takeRetainedValue()
      idle.handler = nil
    }
  }
}

// MARK: - EventLoop

extension EventLoop {

  /// http://docs.libuv.org/en/v1.x/async.html
  public func execute(_ handler: @escaping Handler<Void>) {
    Task(eventLoop: self, handler: handler).start()
  }
}
