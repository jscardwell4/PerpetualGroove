//
//  String+RegularExpression.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/26/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension String {

  /**
  sub:template:

  - parameter regex: RegularExpression
  - parameter template: String

  - returns: String
  */
  public func sub(regex: RegularExpression, _ template: String) -> String {
    return regex.stringByReplacingMatchesInString(self, withTemplate: template)
  }

  /**
  sub:replacement:

  - parameter regex: RegularExpression
  - parameter replacement: (RegularExpression.Match) -> String

  - returns: String
  */
  public func sub(regex: RegularExpression, _ replacement: (RegularExpression.Match) -> String) -> String {
    return regex.stringByReplacingMatchesInString(self, usingBlock: replacement)
  }

  /**
  subInPlace:template:

  - parameter regex: RegularExpression
  - parameter template: String
  */
  public mutating func subInPlace(regex: RegularExpression, _ template: String) { self = sub(regex, template) }

  /**
  subInPlace:replacement:

  - parameter regex: RegularExpression
  - parameter replacement: (RegularExpression.Match) -> String
  */
  public mutating func subInPlace(regex: RegularExpression, _ replacement: (RegularExpression.Match) -> String) {
    self = sub(regex, replacement)
  }

}


