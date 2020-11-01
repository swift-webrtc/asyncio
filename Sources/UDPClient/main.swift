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
    try socket.connect(to: SocketAddress("172.217.213.127:19302")!)
  } catch {
    socket.close()
    print(error)
    return
  }

  let message = [0, 1, 0, 0, 33, 18, 164, 66, 214, 202, 146, 171, 226, 237, 64, 151, 194, 143, 91, 7] as [UInt8]
  message.withUnsafeBytes { data in
    socket.send(data) { result in
      print("Send: \(result)")
    }
  }

  EventLoop.default.schedule(delay: .seconds(10)) { timer in
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
