//
//  ErrorType.swift
//  MoonKit
//
//  Created by Jason Cardwell on 1/21/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public extension ErrorType where Self:RawRepresentable, Self.RawValue == String {
  public var description: String { return rawValue }
}

public protocol WrappedErrorType: ErrorType {
  var underlyingError: ErrorType? { get }
}

public protocol ErrorMessageType: ErrorType, Named, CustomStringConvertible {
  var reason: String { get }
}

public extension ErrorMessageType {
  public var description: String {
    return "\(name) - \(reason)"
  }
}

public protocol ExtendedErrorType: ErrorMessageType, CustomStringConvertible {
  var line: UInt { get set }
  var function: String { get set }
  var file: String { get set }
  var reason: String { get set }
  var name: String { get }
  init()
  init(line: UInt, function: String, file: String, reason: String)
}

public extension ExtendedErrorType {
  public init(line: UInt = __LINE__,
              function: String = __FUNCTION__,
              file: String = __FILE__,
              reason: String)
  {
    self.init()
    self.line = line; self.function = function; self.file = file; self.reason = reason
  }
  public var description: String {
    return "\(name) <\((file as NSString).lastPathComponent):\(line)> \(function)  \(reason)"
  }
}

