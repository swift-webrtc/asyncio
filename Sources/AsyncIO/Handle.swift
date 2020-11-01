//
//  Handle.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/26.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

/// http://docs.libuv.org/en/v1.x/handle.html
internal protocol HandleProtocol {
  var data: UnsafeMutableRawPointer! { get set }
  init()
}

extension uv_idle_t: HandleProtocol {}
extension uv_prepare_t: HandleProtocol {}
extension uv_check_t: HandleProtocol {}
extension uv_async_t: HandleProtocol {}
extension uv_timer_t: HandleProtocol {}
extension uv_udp_t: HandleProtocol {}

internal final class Handle<T: HandleProtocol> {
  internal var unsafe: UnsafeMutablePointer<T>
  internal var data: UnsafeMutableRawPointer? {
    get { unsafe.pointee.data }
    set { unsafe.pointee.data = newValue }
  }
  internal var isActive: Bool {
    withUnsafeHandle({ uv_is_active($0) != 0 })
  }
  internal var isClosing: Bool {
    withUnsafeHandle({ uv_is_closing($0) != 0 })
  }

  internal init(eventLoop: EventLoop, initFn: (UnsafeMutablePointer<uv_loop_t>, UnsafeMutablePointer<T>) -> Int32) {
    self.unsafe = UnsafeMutablePointer.allocate(capacity: 1)
    self.unsafe.initialize(to: T())
    precondition(initFn(eventLoop.handle, unsafe) >= 0)
  }

  deinit {
    unsafe.deallocate()
    logger.debug("\(self) is deinit")
  }

  internal func withUnsafeHandle<T>(_ body: (UnsafePointer<uv_handle_t>) throws -> T) rethrows -> T {
    try unsafe.withMemoryRebound(to: uv_handle_t.self, capacity: 1, { try body($0) })
  }

  internal func withUnsafeMutableHandle<T>(_ body: (UnsafeMutablePointer<uv_handle_t>) throws -> T) rethrows -> T {
    try unsafe.withMemoryRebound(to: uv_handle_t.self, capacity: 1, { try body($0) })
  }

  internal func close(_ handler: @escaping uv_close_cb) {
    withUnsafeMutableHandle {
      uv_close($0, handler)
    }
  }
}
