//
//  main.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/24.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import AsyncIO
import Core

func main() throws {
  do {
    let address = try DNSResolver.query("google.com")
    print("Query success: \(address)")
  } catch {
    print("Query failed: \(error)")
  }

  DNSResolver.query("baidu.com:80") { result in
    switch result {
    case .success(let address):
      print("Query success: \(address)")
    case .failure(let error):
      print("Query failed: \(error)")
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
