//
//  main.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/23.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

final class Echo: UDPSocketDelegate {

  func socket(_ socket: UDPSocket, didReceive data: UnsafeRawBufferPointer, peerAddress address: SocketAddress) {
    print("Recv \(data.count) bytes from \(address)")
  }

  func socket(_ socket: UDPSocket, didCloseWith error: Error?) {
    print("Closed")
  }
}

func main() throws {
  let echo = Echo()
  let socket = UDPSocket()
  socket.delegate = echo
  do {
    try socket.bind(to: SocketAddress("0.0.0.0:3478")!)
    print("Listen at \(socket.localAddress!)")
  } catch {
    socket.close()
    print(error)
  }

  EventLoop.default.schedule(delay: .seconds(30)) { timer in
    socket.close()
  }

  try EventLoop.default.run()
  try EventLoop.default.close()
}

do {
  LoggerConfiguration.default.logLevel = .trace
  try main()
} catch {
  print(error)
}
