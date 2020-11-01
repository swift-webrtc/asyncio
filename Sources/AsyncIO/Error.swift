//
//  Error.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/22.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import CLibuv

public struct AsyncIOError: Error {
  public let code: Int
  public let message: String

  internal init(code: Int32) {
    self.code = Int(code)
    self.message = String(cString: uv_strerror(code))
  }

  internal init(code: Int, message: String) {
    self.code = code
    self.message = message
  }
}

@discardableResult
internal func check<T>(_ body: @autoclosure () -> T) throws -> T where T: FixedWidthInteger {
  let ret = body()
  if ret < 0 {
    throw AsyncIOError(code: Int32(ret))
  }
  return ret
}
