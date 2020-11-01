//
//  main.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/23.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

final class Echo: TCPStreamDelegate {

  func stream(_ stream: TCPStream, didReceive data: UnsafeRawBufferPointer) {
    print("Recv: \(data.count)")
    print("Recv: \(String(decoding: data.bindMemory(to: UInt8.self), as: UTF8.self))")
    stream.close()
  }

  func stream(_ stream: TCPStream, didCloseWith error: Error?) {
    print("Closed")
  }
}

func main() throws {
  let echo = Echo()
  let socket = TCPStream()
  socket.delegate = echo
  socket.connect(to: SocketAddress("127.0.0.1:9090")!) { result in
    switch result {
    case .success:
      print("Connect success")

      var request = """
      GET /hello/world HTTP/1.1\r\n\
      Host: 127.0.0.1:9090\r\n\
      Connection: keep-alive\r\n\
      Upgrade-Insecure-Requests: 1\r\n\
      User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.98 Safari/537.36\r\n\
      Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8\r\n\
      Accept-Encoding: gzip, deflate, br\r\n\
      Accept-Language: zh-CN,zh;q=0.9,en;q=0.8\r\n\r\n
      """
      request.withUTF8 { data in
        socket.write(UnsafeRawBufferPointer(start: data.baseAddress, count: data.count)) { result in
          switch result {
          case .success:
            print("Write success")
          case .failure(let error):
            print("Write failed: \(error)")
            socket.close()
          }
        }
      }
    case .failure(let error):
      print("Connect failed: \(error)")
      socket.close()
    }
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
