//
//  NSShadow+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/21/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension NSShadow: JSONValueConvertible {
  public var jsonValue: JSONValue {
    var obj = ObjectJSONValue(["offset": shadowOffset.jsonValue, "radius": shadowBlurRadius.jsonValue])
    if shadowColor != nil { obj["color"] = (shadowColor as! UIColor).jsonValue }
    return obj.jsonValue
  }
}

extension NSShadow /*: JSONValueInitializable */ {
  public convenience init?(_ jsonValue: JSONValue?) {
    self.init()
    if let object = ObjectJSONValue(jsonValue) {
      if let offset = CGSize(object["offset"]) { shadowOffset = offset }
      if let radius = CGFloat(object["radius"]) { shadowBlurRadius = radius }
      if let color = UIColor(object["color"]) { shadowColor = color }
    }
  }
}

extension NSShadow {
  public convenience init(color: AnyObject!, offset: CGSize, blurRadius: CGFloat) {
    self.init()
    self.shadowColor = color
    self.shadowOffset = offset
    self.shadowBlurRadius = blurRadius
  }

  public var color: UIColor! { return shadowColor as? UIColor }

  public func setShadow() {
    CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(),
                                shadowOffset,
                                shadowBlurRadius,
                                (shadowColor as! UIColor).CGColor)
  }

  public func shadowWithColor(color: AnyObject!) -> NSShadow {
    return NSShadow(color: color, offset: shadowOffset, blurRadius: shadowBlurRadius)
  }

  public func shadowWithAlpha(alpha: CGFloat) -> NSShadow {
    return NSShadow(color: color.colorWithAlphaComponent(alpha), offset: shadowOffset, blurRadius: shadowBlurRadius)
  }
}