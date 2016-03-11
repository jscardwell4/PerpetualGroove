//
//  NSFileManager+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 3/10/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public extension NSFileManager {

  public static func withDefaultManager<R>(@noescape body: (NSFileManager) throws -> R) rethrows -> R {
    return try body(defaultManager())
  }

}