//
//  NSLayoutConstraint+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/7/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
//import UIKit

extension NSLayoutConstraint {

  public var prettyDescription: String {
    let pseudo = PseudoConstraint(self)
    return pseudo.validPseudo ? pseudo.description : description
  }

  /**
  splitFormat:

  - parameter format: String

  - returns: [String]
  */
  public class func splitFormat(format: String) -> [String] {
    return "\n".split(format.sub("::", "\n").sub("[⏎;]", "\n").sub("  +", " "))
      .map({$0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())})
      .filter(invert({$0.isEmpty}))
  }

  public convenience init(_ pseudoConstraint: PseudoConstraint) {
    assert(pseudoConstraint.validConstraint)
    self.init(item: pseudoConstraint.firstObject!,
              attribute: pseudoConstraint.firstAttribute.NSLayoutAttributeValue,
              relatedBy: pseudoConstraint.relation.NSLayoutRelationValue,
              toItem: pseudoConstraint.secondObject,
              attribute: pseudoConstraint.secondAttribute.NSLayoutAttributeValue,
              multiplier: CGFloat(pseudoConstraint.multiplier),
              constant: CGFloat(pseudoConstraint.constant))
    identifier = pseudoConstraint.identifier
    priority = pseudoConstraint.priority
  }

  /**
  constraintsByParsingFormat:options:metrics:views:

  - parameter format: String
  - parameter options: NSLayoutFormatOptions = nil
  - parameter metrics: [String AnyObject]? = nil
  - parameter views: [String AnyObject]? = nil

  - returns: [NSLayoutConstraint]
  */
  public class func constraintsByParsingFormat(format: String,
                                       options: NSLayoutFormatOptions = NSLayoutFormatOptions(rawValue: 0),
                                       metrics: [String:AnyObject] = [:],
                                         views: [String:AnyObject] = [:]) -> [NSLayoutConstraint]
  {
    var constraints: [NSLayoutConstraint] = []

    for string in splitFormat(format) {
      if let c = PseudoConstraint(string)?.expanded.compressedMap({$0.constraintWithObjects(views)}) where c.count > 0 {
          constraints.extend(c)
      } else {
        let c = constraintsWithVisualFormat(string, options: options, metrics: metrics, views: views) as [NSLayoutConstraint]
        constraints.extend(c)
      }
    }

    return constraints
  }

}

extension NSLayoutAttribute {
  public var axis: UILayoutConstraintAxis {
    switch self {
      case .Width,
           .Left, .LeftMargin,
           .Leading, .LeadingMargin,
           .Right, .RightMargin,
           .Trailing, .TrailingMargin,
           .CenterX, .CenterXWithinMargins:
        return .Horizontal
      default: return .Vertical
    }
  }
}