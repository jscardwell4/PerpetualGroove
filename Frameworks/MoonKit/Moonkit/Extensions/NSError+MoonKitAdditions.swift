//
//  NSError+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 3/3/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension NSError {
  /**
  initWithDomain:code:underlyingErrors:var:

  - parameter domain: String
  - parameter code: Int
  - parameter underlyingErrors: [NSError]
  - parameter userInfo: [NSObject
  */
  public
  convenience init(domain: String, code: Int, underlyingErrors: [NSError], var userInfo: [NSObject:AnyObject]? = nil) {
    if userInfo == nil { userInfo = [:] }
    userInfo![NSUnderlyingErrorKey] = underlyingErrors
    self.init(domain: domain, code: code, userInfo: userInfo!)
  }
}