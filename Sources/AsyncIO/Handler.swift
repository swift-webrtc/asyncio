//
//  Handler.swift
//  webrtc-asyncio
//
//  Created by sunlubo on 2020/10/22.
//  Copyright © 2020 sunlubo. All rights reserved.
//

public typealias Handler<T> = (T) -> Void
public typealias ResultHandler<T> = (Result<T, Error>) -> Void
