//
//  DNSResolver.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/9/6.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

public enum DNSResolver {

  public static func query(_ hostname: String, eventLoop: EventLoop = .default) throws -> SocketAddress {
    guard let (host, port) = parse(hostname) else {
      throw AsyncIOError(code: UV_EINVAL.rawValue)
    }

    var req = uv_getaddrinfo_t()
    defer {
      uv_freeaddrinfo(req.addrinfo)
    }
    try check(uv_getaddrinfo(eventLoop.handle, &req, nil, host, port, nil))
    return SocketAddress(req.addrinfo.pointee.ai_addr.convert(to: sockaddr_storage.self))!
  }

  public static func query(_ hostname: String, eventLoop: EventLoop = .default, completion handler: @escaping ResultHandler<SocketAddress>) {
    guard let (host, port) = parse(hostname) else {
      handler(.failure(AsyncIOError(code: UV_EINVAL.rawValue)))
      return
    }

    let request = Request<uv_getaddrinfo_t, SocketAddress>(handler: handler)
    let ret = uv_getaddrinfo(eventLoop.handle, request.unsafe, { req, status, addrinfo in
      defer {
        uv_freeaddrinfo(addrinfo)
      }

      let request = Unmanaged<Request<uv_getaddrinfo_t, SocketAddress>>.fromOpaque(req!.pointee.data).takeRetainedValue()
      if status == 0 {
        request.onSuccess(SocketAddress(addrinfo!.pointee.ai_addr.convert(to: sockaddr_storage.self))!)
      } else {
        request.onError(AsyncIOError(code: status))
      }
    }, host, port, nil)
    if ret >= 0 {
      request.data = Unmanaged.passRetained(request).toOpaque()
    } else {
      request.onError(AsyncIOError(code: ret))
    }
  }

  internal static func parse(_ hostname: String) -> (host: String, port: String?)? {
    let parts = hostname.split(separator: ":")
    switch parts.count {
    case 1:
      return (String(parts[0]), nil)
    case 2:
      return (String(parts[0]), String(parts[1]))
    default:
      return nil
    }
  }
}
