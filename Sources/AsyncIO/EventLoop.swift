//
//  EventLoop.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/22.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

public final class EventLoop {
  public static let `default`: EventLoop = {
    EventLoop(handle: uv_default_loop())
  }()

  internal var handle: UnsafeMutablePointer<uv_loop_t>

  public init() {
    self.handle = UnsafeMutablePointer.allocate(capacity: 1)
    self.handle.initialize(to: uv_loop_t())
    precondition(uv_loop_init(handle) >= 0, "uv_loop_init")
  }

  internal init(handle: UnsafeMutablePointer<uv_loop_t>) {
    self.handle = handle
  }

  deinit {
    handle.deallocate()
    logger.debug("\(self) is deinit")
  }

  public func run() throws {
    try check(uv_run(handle, UV_RUN_DEFAULT))
  }

  public func close() throws {
    stop()
    try check(uv_loop_close(handle))
  }

  internal func stop() {
    uv_stop(handle)
  }
}
