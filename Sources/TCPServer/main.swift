//
//  main.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/23.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

final class Echo: TCPListenerDelegate {

  func listener(_ listener: TCPListener, didAccept stream: TCPStream) {
    print("Accept connection from \(stream.peerAddress!)")

    var response = """
    HTTP/1.1 200 OK\r\n\
    hello\r\n
    """
    response.withUTF8 { data in
      stream.write(UnsafeRawBufferPointer(start: data.baseAddress, count: data.count)) { result in
        switch result {
        case .success:
          print("Write success")
        case .failure(let error):
          print("Write failed: \(error)")
        }
        stream.close()
      }
    }
  }

  func listener(_ listener: TCPListener, didCloseWith error: Error?) {
    print("Closed")
  }
}

func main() throws {
  let echo = Echo()
  let listener = TCPListener()
  listener.delegate = echo
  do {
    try listener.listen(at: SocketAddress("127.0.0.1:9090")!)
    print("Listen at \(listener.localAddress!)")
  } catch {
    listener.close()
    print(error)
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
