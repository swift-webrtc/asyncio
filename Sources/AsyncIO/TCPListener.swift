//
//  TCPListener.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/22.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

public protocol TCPListenerDelegate: AnyObject {
  func listener(_ listener: TCPListener, didAccept stream: TCPStream)
  func listener(_ listener: TCPListener, didCloseWith error: Error?)
}

public final class TCPListener {
  internal let eventLoop: EventLoop
  internal let handle: Handle<uv_tcp_t>

  public weak var delegate: TCPListenerDelegate?

  public var localAddress: SocketAddress? {
    .make(handle, fn: uv_tcp_getsockname)
  }
  public var peerAddress: SocketAddress? {
    .make(handle, fn: uv_tcp_getpeername)
  }

  public init(eventLoop: EventLoop = .default) {
    self.eventLoop = eventLoop
    self.handle = Handle(eventLoop: eventLoop, initFn: uv_tcp_init)
    self.handle.data = Unmanaged.passRetained(self).toOpaque()
  }

  public func listen(at address: SocketAddress, backlog: Int = 1024) throws {
    try check(address.withSockAddr({ ptr, _ in uv_tcp_bind(handle.unsafe, ptr, 0) }))
    try check(listen(backlog: backlog))
  }

  public func close() {
    handle.close {
      let listener = Unmanaged<TCPListener>.fromOpaque($0!.pointee.data).takeRetainedValue()
      listener.delegate?.listener(listener, didCloseWith: nil)
    }
  }

  internal func listen(backlog: Int) -> Int32 {
    handle.withUnsafeMutableStream {
      uv_listen($0, Int32(backlog)) { handle, status in
        let listener = Unmanaged<TCPListener>.fromOpaque(handle!.pointee.data).takeUnretainedValue()
        guard status >= 0 else {
          listener.delegate?.listener(listener, didCloseWith: AsyncIOError(code: status))
          listener.delegate = nil
          listener.close()
          return
        }

        let stream = TCPStream(eventLoop: listener.eventLoop)
        let ret = stream.handle.withUnsafeMutableStream {
          uv_accept(handle, $0)
        }
        if ret >= 0 {
          listener.delegate?.listener(listener, didAccept: stream)
        } else {
          stream.close()
          logger.warning("uv_accept failed: \(AsyncIOError(code: ret))")
        }
      }
    }
  }
}
