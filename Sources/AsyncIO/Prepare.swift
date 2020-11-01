//
//  Prepare.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/26.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

internal final class Prepare: Cancellable {
  internal let handle: Handle<uv_prepare_t>
  internal var handler: Handler<Prepare>?

  internal init(eventLoop: EventLoop, handler: @escaping Handler<Prepare>) {
    self.handle = Handle(eventLoop: eventLoop, initFn: uv_prepare_init)
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
    self.handler = handler
  }

  internal func start() {
    uv_prepare_start(handle.unsafe) {
      let idle = Unmanaged<Prepare>.fromOpaque($0!.pointee.data).takeUnretainedValue()
      idle.handler?(idle)
    }
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

  /// http://docs.libuv.org/en/v1.x/prepare.html
  @discardableResult
  public func addPrepareHandler(_ handler: @escaping Handler<Cancellable>) -> Cancellable {
    let idle = Prepare(eventLoop: self, handler: handler)
    idle.start()
    return idle
  }
}
