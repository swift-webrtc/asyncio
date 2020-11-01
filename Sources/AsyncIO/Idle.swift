//
//  Idle.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/24.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

internal final class Idle: Cancellable {
  internal let handle: Handle<uv_idle_t>
  internal var handler: Handler<Idle>?

  internal init(eventLoop: EventLoop, handler: @escaping Handler<Idle>) {
    self.handle = Handle(eventLoop: eventLoop, initFn: uv_idle_init)
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
    self.handler = handler
  }

  internal func start() {
    uv_idle_start(handle.unsafe) {
      let idle = Unmanaged<Idle>.fromOpaque($0!.pointee.data).takeUnretainedValue()
      idle.handler?(idle)
    }
  }

  internal func cancel() {
    handle.close {
      let idle = Unmanaged<Idle>.fromOpaque($0!.pointee.data).takeRetainedValue()
      idle.handler = nil
    }
  }
}

// MARK: - EventLoop

extension EventLoop {

  /// http://docs.libuv.org/en/v1.x/idle.html
  @discardableResult
  public func addIdleHandler(_ handler: @escaping Handler<Cancellable>) -> Cancellable {
    let idle = Idle(eventLoop: self, handler: handler)
    idle.start()
    return idle
  }
}
