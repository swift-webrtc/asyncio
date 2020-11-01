//
//  TCPStream.swift
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

public protocol TCPStreamDelegate: AnyObject {
  func stream(_ stream: TCPStream, didReceive data: UnsafeRawBufferPointer)
  func stream(_ stream: TCPStream, didCloseWith error: Error?)
}

public final class TCPStream {
  internal let handle: Handle<uv_tcp_t>
  internal var closeHandler: Handler<Void>?

  public weak var delegate: TCPStreamDelegate?

  public var localAddress: SocketAddress? {
    .make(handle, fn: uv_tcp_getsockname)
  }
  public var peerAddress: SocketAddress? {
    .make(handle, fn: uv_tcp_getpeername)
  }

  public init(eventLoop: EventLoop = .default) {
    self.handle = Handle(eventLoop: eventLoop, initFn: uv_tcp_init)
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
  }

  public func connect(to address: SocketAddress, completion handler: @escaping ResultHandler<Void>) {
    let request = Request<uv_connect_t, Void>(handler: handler)
    let ret = address.withSockAddr { ptr, _ in
      uv_tcp_connect(request.unsafe, handle.unsafe, ptr) { req, status in
        let request = Unmanaged<Request<uv_connect_t, Void>>.fromOpaque(req!.pointee.data).takeRetainedValue()
        guard status >= 0 else {
          request.handler?(.failure(AsyncIOError(code: status)))
          return
        }

        let stream = Unmanaged<TCPStream>.fromOpaque(req!.pointee.handle.pointee.data).takeUnretainedValue()
        let ret = stream.start()
        if ret >= 0 {
          request.onSuccess(())
        } else {
          request.onError(AsyncIOError(code: ret))
        }
      }
    }
    if ret >= 0 {
      request.data = Unmanaged.passRetained(request).toOpaque()
    } else {
      request.onError(AsyncIOError(code: ret))
    }
  }

  public func write(_ data: UnsafeRawBufferPointer, completion handler: @escaping ResultHandler<Void>) {
    handle.write(data, completion: handler)
  }

  public func close() {
    handle.close {
      let stream = Unmanaged<TCPStream>.fromOpaque($0!.pointee.data).takeRetainedValue()
      stream.delegate?.stream(stream, didCloseWith: nil)
    }
  }

  internal func start() -> Int32 {
    handle.withUnsafeMutableStream {
      uv_read_start(
        $0,
        { handle, suggested_size, buf in
          buf?.pointee.base = malloc(suggested_size).bindMemory(to: Int8.self, capacity: suggested_size)
          buf?.pointee.len = suggested_size
        },
        { handle, nread, buf in
          defer {
            free(buf?.pointee.base)
          }

          let stream = Unmanaged<TCPStream>.fromOpaque(handle!.pointee.data).takeUnretainedValue()
          guard nread >= 0 else {
            stream.delegate?.stream(stream, didCloseWith: AsyncIOError(code: Int32(nread)))
            stream.delegate = nil
            stream.close()
            return
          }

          if nread != 0 {
            stream.delegate?.stream(stream, didReceive: UnsafeRawBufferPointer(start: buf!.pointee.base, count: nread))
          }
        }
      )
    }
  }
}
