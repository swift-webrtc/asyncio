//
//  Request.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/27.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

/// http://docs.libuv.org/en/v1.x/request.html
internal protocol RequestProtocol {
  var data: UnsafeMutableRawPointer! { get set }
  init()
}

extension uv_connect_t: RequestProtocol {}
extension uv_write_t: RequestProtocol {}
extension uv_udp_send_t: RequestProtocol {}
extension uv_getaddrinfo_t: RequestProtocol {}

internal final class Request<T: RequestProtocol, R> {
  internal var unsafe: UnsafeMutablePointer<T>
  internal var handler: ResultHandler<R>?
  internal var data: UnsafeMutableRawPointer? {
    get { unsafe.pointee.data }
    set { unsafe.pointee.data = newValue }
  }

  internal init(handler: ResultHandler<R>?) {
    self.unsafe = UnsafeMutablePointer.allocate(capacity: 1)
    self.unsafe.initialize(to: T())
    self.handler = handler
  }

  deinit {
    unsafe.deallocate()
    logger.debug("\(self) is deinit")
  }

  internal func withUnsafeRequest<T>(_ body: (UnsafePointer<uv_req_t>) throws -> T) rethrows -> T {
    try unsafe.withMemoryRebound(to: uv_req_t.self, capacity: 1, { try body($0) })
  }

  internal func withUnsafeMutableRequest<T>(_ body: (UnsafeMutablePointer<uv_req_t>) throws -> T) rethrows -> T {
    try unsafe.withMemoryRebound(to: uv_req_t.self, capacity: 1, { try body($0) })
  }

  internal func cancel() {
    _ = withUnsafeMutableRequest {
      uv_cancel($0)
    }
  }
}

extension Request {

  internal func onSuccess(_ value: R) {
    handler?(.success(value))
    handler = nil
  }

  internal func onError(_ error: Error) {
    handler?(.failure(error))
    handler = nil
  }
}
