//
//  Check.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/26.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

internal final class Check: Cancellable {
  internal let handle: Handle<uv_check_t>
  internal var handler: Handler<Check>?

  internal init(eventLoop: EventLoop, handler: @escaping Handler<Check>) {
    self.handle = Handle(eventLoop: eventLoop, initFn: uv_check_init)
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
    self.handler = handler
  }

  internal func start() {
    uv_check_start(handle.unsafe) {
      let idle = Unmanaged<Check>.fromOpaque($0!.pointee.data).takeUnretainedValue()
      idle.handler?(idle)
    }
  }

  internal func cancel() {
    handle.close {
      let idle = Unmanaged<Check>.fromOpaque($0!.pointee.data).takeRetainedValue()
      idle.handler = nil
    }
  }
}

// MARK: - EventLoop

extension EventLoop {

  /// http://docs.libuv.org/en/v1.x/check.html
  @discardableResult
  public func addCheckHandler(_ handler: @escaping Handler<Cancellable>) -> Cancellable {
    let check = Check(eventLoop: self, handler: handler)
    check.start()
    return check
  }
}
