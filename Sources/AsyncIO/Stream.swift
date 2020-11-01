//
//  Stream.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/27.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

internal protocol StreamProtocol: HandleProtocol {}

extension uv_stream_t: StreamProtocol {}
extension uv_tcp_t: StreamProtocol {}

extension Handle where T: StreamProtocol {

  internal func withUnsafeStream<T>(_ body: (UnsafePointer<uv_stream_t>) throws -> T) rethrows -> T {
    try unsafe.withMemoryRebound(to: uv_stream_t.self, capacity: 1, { try body($0) })
  }

  internal func withUnsafeMutableStream<T>(_ body: (UnsafeMutablePointer<uv_stream_t>) throws -> T) rethrows -> T {
    try unsafe.withMemoryRebound(to: uv_stream_t.self, capacity: 1, { try body($0) })
  }

  internal func write(_ data: UnsafeRawBufferPointer, completion handler: @escaping ResultHandler<Void>) {
    let request = Request<uv_write_t, Void>(handler: handler)
    var buf = data.uvBuf
    let ret = withUnsafeMutableStream {
      uv_write(request.unsafe, $0, &buf, 1) { req, status in
        let request = Unmanaged<Request<uv_write_t, Void>>.fromOpaque(req!.pointee.data).takeRetainedValue()
        if status == 0 {
          request.onSuccess(())
        } else {
          request.onError(AsyncIOError(code: status))
        }
      }
    }
    if ret >= 0 {
      request.data = Unmanaged.passRetained(request).toOpaque()
    } else {
      request.onError(AsyncIOError(code: ret))
    }
  }
}
