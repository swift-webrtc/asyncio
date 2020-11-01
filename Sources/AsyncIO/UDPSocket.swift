//
//  UDPSocket.swift
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

public protocol UDPSocketDelegate: AnyObject {
  func socket(_ socket: UDPSocket, didReceive data: UnsafeRawBufferPointer, peerAddress address: SocketAddress)
  func socket(_ socket: UDPSocket, didCloseWith error: Error?)
}

public final class UDPSocket {
  internal let handle: Handle<uv_udp_t>
  internal var closeHandler: Handler<Void>?

  public weak var delegate: UDPSocketDelegate?

  public var localAddress: SocketAddress? {
    .make(handle, fn: uv_udp_getsockname)
  }
  public var peerAddress: SocketAddress? {
    .make(handle, fn: uv_udp_getpeername)
  }

  public init(eventLoop: EventLoop = .default) {
    self.handle = Handle(eventLoop: eventLoop, initFn: uv_udp_init)
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
  }

  public func bind(to address: SocketAddress = .init(ip: .v4(.any), port: 0)) throws {
    try check(address.withSockAddr({ ptr, _ in uv_udp_bind(handle.unsafe, ptr, UV_UDP_REUSEADDR.rawValue) }))
    try start()
  }

  public func connect(to address: SocketAddress) throws {
    try check(address.withSockAddr({ ptr, _ in uv_udp_connect(handle.unsafe, ptr) }))
    try start()
  }

  internal func start() throws {
    let ret = uv_udp_recv_start(
      handle.unsafe,
      { handle, suggested_size, buf in
        buf?.pointee.base = malloc(suggested_size).bindMemory(to: Int8.self, capacity: suggested_size)
        buf?.pointee.len = suggested_size
      },
      { handle, nread, buf, addr, flags in
        defer {
          free(buf?.pointee.base)
        }

        let socket = Unmanaged<UDPSocket>.fromOpaque(handle!.pointee.data).takeUnretainedValue()
        guard nread >= 0 else {
          socket.delegate?.socket(socket, didCloseWith: AsyncIOError(code: Int32(nread)))
          socket.delegate = nil
          socket.close()
          return
        }

        if nread != 0 {
          let address = SocketAddress(addr!.withMemoryRebound(to: sockaddr_storage.self, capacity: 1, \.pointee))!
          socket.delegate?.socket(socket, didReceive: UnsafeRawBufferPointer(start: buf!.pointee.base, count: nread), peerAddress: address)
        }
      }
    )
    if ret < 0 {
      throw AsyncIOError(code: ret)
    }
  }

  public func send(
    _ data: UnsafeRawBufferPointer,
    to address: SocketAddress? = nil,
    completion handler: ResultHandler<Void>? = nil
  ) {
    if let address = address {
      address.withSockAddr { ptr, _ in
        send(data, to: ptr, completion: handler)
      }
    } else {
      send(data, to: Optional<UnsafePointer<sockaddr>>.none, completion: handler)
    }
  }

  public func close() {
    handle.close {
      let socket = Unmanaged<UDPSocket>.fromOpaque($0!.pointee.data).takeRetainedValue()
      socket.delegate?.socket(socket, didCloseWith: nil)
    }
  }

  internal func send(
    _ data: UnsafeRawBufferPointer,
    to address: UnsafePointer<sockaddr>?,
    completion handler: ResultHandler<Void>?
  ) {
    let request = Request<uv_udp_send_t, Void>(handler: handler)
    var buf = data.uvBuf
    let ret = uv_udp_send(request.unsafe, handle.unsafe, &buf, 1, address) { req, status in
      let request = Unmanaged<Request<uv_udp_send_t, Void>>.fromOpaque(req!.pointee.data).takeRetainedValue()
      if status == 0 {
        request.onSuccess(())
      } else {
        request.onError(AsyncIOError(code: status))
      }
    }
    if ret >= 0 {
      request.data = Unmanaged.passRetained(request).toOpaque()
    } else {
      request.onError(AsyncIOError(code: ret))
    }
  }
}
