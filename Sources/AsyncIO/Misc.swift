//
//  UnsafeExt.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/22.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

extension UnsafeRawBufferPointer {

  internal var uvBuf: uv_buf_t {
    let base = UnsafeMutablePointer<Int8>(mutating: bindMemory(to: Int8.self).baseAddress!)
    return uv_buf_init(base, UInt32(count))
  }
}

extension SocketAddress {

  internal static func make<T>(
    _ handle: Handle<T>,
    fn: (UnsafePointer<T>, UnsafeMutablePointer<sockaddr>, UnsafeMutablePointer<Int32>) -> Int32
  ) -> SocketAddress? {
    var addr = sockaddr_storage()
    do {
      try addr.withMutableSockAddr {
        var len = Int32($1)
        try check(fn(handle.unsafe, $0, &len))
      }
      return SocketAddress(addr)
    } catch {
      logger.error("\(error)")
    }
    return nil
  }
}
