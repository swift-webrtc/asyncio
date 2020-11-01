//
//  URI.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/9/19.
//  Copyright © 2020 sunlubo. All rights reserved.
//

public func parseURI(_ string: String) -> (scheme: String, host: IPAddress, port: SocketAddress.Port?)? {
  let parts = string.split(separator: ":")
  let host: IPAddress?
  let port: SocketAddress.Port?
  switch parts.count {
  case 2:
    host = try? DNSResolver.query(parts.dropFirst().joined(separator: ":")).ip
    port = nil
  case 3:
    host = try? DNSResolver.query(parts.dropFirst().dropLast().joined(separator: ":")).ip
    port = UInt16(parts[2]).flatMap(SocketAddress.Port.init(rawValue:))
  default:
    host = nil
    port = nil
  }
  if host == nil || parts.count == 3 && port == nil {
    return nil
  }

  return (String(parts[0]), host!, port)
}
