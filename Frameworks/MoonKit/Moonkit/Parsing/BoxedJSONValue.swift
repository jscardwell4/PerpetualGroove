//
//  BoxedJSONValue.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/** Wrapper for using `JSONValue` where a class is needed */
public class BoxedJSONValue: NSCoding {
  public let jsonValue: JSONValue
  public init(_ jsonValue: JSONValue) { self.jsonValue = jsonValue }
  @objc public func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(jsonValue.rawValue)
  }
  @objc public required init?(coder aDecoder: NSCoder) {
    if let rawValue = aDecoder.decodeObject() as? String,
      jsonValue = JSONValue(rawValue: rawValue)
    {
      self.jsonValue = jsonValue
    } else { jsonValue = .Null }
  }
}
