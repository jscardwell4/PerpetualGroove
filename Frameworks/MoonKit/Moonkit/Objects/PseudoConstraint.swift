//
//  PseudoConstraint.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/25/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public let 𝗩 = UILayoutConstraintAxis.Vertical
public let 𝗛 = UILayoutConstraintAxis.Horizontal

private let UILayoutPriorityRequired: Float = 1000.0 // to avoid linker error

public struct PseudoConstraint {

  public typealias ItemName = String
  public var firstItem: ItemName?
  public var firstObject: AnyObject? { didSet { updateFirstItem() } }

  private mutating func updateFirstItem() {
    if let f = firstObject as? Named { firstItem = itemNameFromString(f.name) }
    else if let f = firstObject as? UIView, nametag = f.nametag { firstItem = itemNameFromString(nametag) }
    else { firstItem = firstObject != nil ? "item1" : nil }
  }

  private mutating func updateSecondItem() {
    if let f = secondObject as? Named { secondItem = itemNameFromString(f.name) }
    else if let f = secondObject as? UIView, nametag = f.nametag { secondItem = itemNameFromString(nametag) }
    else { secondItem = secondObject != nil ? "item2" : nil }
  }

  public var firstAttribute: Attribute = .NotAnAttribute
  public var relation: Relation = .Equal
  public var secondObject: AnyObject? { didSet { updateSecondItem() } }
  public var secondItem: ItemName?
  public var secondAttribute: Attribute = .NotAnAttribute
  public var constant: Float = 0
  public var multiplier: Float = 1
  public var priority: UILayoutPriority = UILayoutPriorityRequired
  public var identifier: String?

  /**
  itemNameFromString:

  - parameter string: String

  - returns: ItemName?
  */
  private func itemNameFromString(string: String?) -> ItemName? {
    if string == nil { return nil }
    let whitespaceAndNewline = NSCharacterSet.whitespaceAndNewlineCharacterSet()
    let letters = NSCharacterSet.alphanumericCharacterSet()
    var result = ""
    for u in string!.utf16 {
      switch u {
        case whitespaceAndNewline: result += "_"
        case letters: result += String(UnicodeScalar(u))
        default: break
      }
    }
    return result.isEmpty ? nil : result
  }

  /**
  testValidityWithFirstItem:secondItem:

  - parameter f: Any?
  - parameter s: Any?

  - returns: Bool
  */
  private func testValidityWithFirstItem(f: Any?, secondItem s: Any?) -> Bool {
    return f != nil && firstAttribute != .NotAnAttribute && !expandable && (s == nil || secondAttribute != .NotAnAttribute)
  }

  /** Whether the pseudo constraint can actually be turned into an `NSLayoutConstraint` object */
  public var validConstraint: Bool { return testValidityWithFirstItem(firstObject, secondItem: secondObject) }

  /** Whether the pseudo constraint forms a valid 'pseudo' representation of a constraint */
  public var validPseudo: Bool { return testValidityWithFirstItem(firstItem, secondItem: secondItem) }

  /** Returns the array of `PseudoConstraint` objects by expanding a compatible attribute, i.e. 'center' → 'centerX', 'centerY' */
  public var expanded: [PseudoConstraint] {
    switch (firstAttribute, secondAttribute) {
      case (.Center, .Center):
        var x = self; x.firstAttribute = .CenterX; x.secondAttribute = .CenterX
        var y = self; y.firstAttribute = .CenterY; y.secondAttribute = .CenterY
        return [x, y]
    case (.CenterWithinMargins, .CenterWithinMargins):
      var x = self; x.firstAttribute = .CenterXWithinMargins; x.secondAttribute = .CenterXWithinMargins
      var y = self; y.firstAttribute = .CenterYWithinMargins; y.secondAttribute = .CenterYWithinMargins
      return [x, y]
      case (.Size, .Size):
        var w = self; w.firstAttribute = .Width; w.secondAttribute = .Width
        var h = self; h.firstAttribute = .Height; h.secondAttribute = .Height
        return [w, h]
      default:
        return [self]
    }
  }

  /** Whether the `PseudoConstraint` is expansion compatible */
  public var expandable: Bool {
    return firstAttribute == secondAttribute && ([.Center, .Size, .CenterWithinMargins] ∋ firstAttribute)
  }

  /** init */
  public init() {}

  /**
  init:attribute:relatedBy:toItem:attribute:multiplier:constant:priority:identifier:

  - parameter item1: Item
  - parameter attr1: Attribute
  - parameter relation: Relation = Relation.Equal
  - parameter item2: Item? = nil
  - parameter attr2: Attribute = Attribute.NotAnAttribute
  - parameter multiplier: Float = 1.0
  - parameter c: Float = 0.0
  - parameter priority: UILayoutPriority = UILayoutPriorityRequired
  - parameter identifier: String? = nil
  */
  public init(item item1: ItemName,
              attribute attr1: Attribute,
              relatedBy relation: Relation = Relation.Equal,
              toItem item2: ItemName? = nil,
              attribute attr2: Attribute = Attribute.NotAnAttribute,
              multiplier: Float = 1.0,
              constant c: Float = 0.0,
              priority: UILayoutPriority = UILayoutPriorityRequired,
              identifier: String? = nil)
  {
    firstItem       = item1
    firstAttribute  = attr1
    self.relation   = relation
    secondItem      = item2
    secondAttribute = attr2
    self.multiplier = multiplier
    constant        = c
    self.priority   = priority
    self.identifier = identifier
  }

  /**
  initWithFormat:

  - parameter format: String
  */
  public init?(_ format: String) {

    let name = "([\\p{L}$_][\\w]*)"
    let attributes = "|".join("(?:left|right|leading|trailing)(?:Margin)?",
                              "(?:top|bottom)(?:Margin)?",
                              "width",
                              "height",
                              "size",
                              "(?:center[XY]?)(?:WithinMargins)?",
                              "(?:firstB|b)aseline")
    let attribute = "(\(attributes))"
    let item = "\(name)\\.\(attribute)"
    let number = "((?:[-+] *)?\\p{N}+(?:\\.\\p{N}+)?)"
    let m = "(?: *[x*] *\(number))"
    let relatedBy = " *([=≥≤]) *"
    let p = "(?:@ *\(number))"
    let id = "(?:'([\\w ]+)' *)"
    let pattern = "^ *\(id)?\(item)\(relatedBy)(?:\(item)\(m)?)? *\(number)? *\(p)? *$"
    let regex = ~/pattern

    guard let match = regex.firstMatch(format) else { return }

    for case let .Some(capture) in match.captures {
      switch capture.group {
        case 1:
          identifier = capture.string
        case 2:
          firstItem = capture.string
        case 3:
          if let a = Attribute(rawValue: capture.string) { firstAttribute = a } else { return nil }
        case 4:
          if let r = Relation(rawValue: capture.string) { relation = r } else { return nil }
        case 5:
          secondItem = capture.string
        case 6:
          if let a = Attribute(rawValue: capture.string) { secondAttribute = a } else { return nil }
        case 7:
          if !NSScanner(string: capture.string).scanFloat(&multiplier) { return nil }
        case 8:
          if !NSScanner(string: String(capture.string.characters.filter({$0 != " "}))).scanFloat(&constant) { return nil }
        case 9:
          if !NSScanner(string: capture.string).scanFloat(&priority) { return nil }
        default:
          assert(false, "should be unreachable")
      }
    }

  }

  /**
  initWithConstraint:replacements:

  - parameter constraint: NSLayoutConstraint
  - parameter replacements: [String String]
  */
  public init(_ constraint: NSLayoutConstraint) {
    identifier      = constraint.identifier
    firstObject     = constraint.firstItem
    updateFirstItem()
    firstAttribute  = Attribute(constraint.firstAttribute)
    relation        = Relation(constraint.relation)
    secondObject    = constraint.secondItem
    updateSecondItem()
    secondAttribute = Attribute(constraint.secondAttribute)
    multiplier      = Float(constraint.multiplier)
    constant        = Float(constraint.constant)
    priority        = constraint.priority
  }

  /**
  pseudoConstraintsByParsingFormat:

  - parameter format: String

  - returns: [PseudoConstraint]
  */
  public static func pseudoConstraintsByParsingFormat(format: String) -> [PseudoConstraint] {
    return flattenedCompressedMap(NSLayoutConstraint.splitFormat(format), {PseudoConstraint($0)?.expanded})
  }

  /**
  constraintWithObjects:object2:

  - parameter object1: AnyObject
  - parameter object2: AnyObject?

  - returns: NSLayoutConstraint?
  */
  public func constraintWithObjects(object1: AnyObject, _ object2: AnyObject?) -> NSLayoutConstraint? {
    if !validPseudo || ((object2 == nil) != (secondItem == nil)) { return nil }
    else {
      let constraint = NSLayoutConstraint(item:       object1,
                                          attribute:  firstAttribute.NSLayoutAttributeValue,
                                          relatedBy:  relation.NSLayoutRelationValue,
                                          toItem:     object2,
                                          attribute:  secondAttribute.NSLayoutAttributeValue,
                                          multiplier: CGFloat(multiplier),
                                          constant:   CGFloat(constant))
      constraint.priority   = priority
      constraint.identifier = identifier
      return constraint
    }
  }

  /**
  constraintWithObjects:

  - parameter objects: [Item AnyObject]

  - returns: NSLayoutConstraint?
  */
  public func constraintWithObjects(objects: [ItemName:AnyObject]) -> NSLayoutConstraint? {
    if let firstItem = self.firstItem, item1: AnyObject = objects[firstItem] {
      return constraintWithObjects(item1, secondItem != nil ? objects[secondItem!] : nil)
    } else { return nil }
  }

  /**
  constraint

  - returns: NSLayoutConstraint?
  */
  public var constraint: NSLayoutConstraint? {
    if !validConstraint { return nil }
    else {
      let constraint = NSLayoutConstraint(item:       firstObject!,
                                          attribute:  firstAttribute.NSLayoutAttributeValue,
                                          relatedBy:  relation.NSLayoutRelationValue,
                                          toItem:     secondObject,
                                          attribute:  secondAttribute.NSLayoutAttributeValue,
                                          multiplier: CGFloat(multiplier),
                                          constant:   CGFloat(constant))
      constraint.priority   = priority
      constraint.identifier = identifier
      return constraint
    }
  }

  /**
  initWithFirst:PseudoConstraint.Attribute):second:PseudoConstraint.Attribute):

  - parameter first: (V1
  - parameter PseudoConstraint.Attribute):
  - parameter second: (V2
  - parameter PseudoConstraint.Attribute):
  */
  public init(first: ViewAttribute, second: ViewAttribute, relation r: Relation = .Equal) {
    firstObject = first.0
    updateFirstItem()
    firstAttribute = first.1
    secondObject = second.0
    updateSecondItem()
    secondAttribute = second.1
    relation = r
  }

  /**
  initWithPair:constant:

  - parameter pair: ViewAttributePair
  - parameter c: Float
  */
  public init(pair: ViewAttribute, constant c: Float, relation r: Relation = .Equal) {
    firstObject = pair.0
    updateFirstItem()
    firstAttribute = pair.1
    secondObject = nil
    secondAttribute = .NotAnAttribute
    relation = r
    constant = c
  }

}

// MARK: Equatable

extension PseudoConstraint: Equatable {}
public func ==(lhs: PseudoConstraint, rhs: PseudoConstraint) -> Bool { return lhs.description == rhs.description }

// MARK: Printable

extension PseudoConstraint: CustomStringConvertible {
  public var description: String {
    if !validPseudo { return "pseudo invalid" }

    var result = ""
    if let i = identifier { result += "'\(i)' " }

    let firstItemString: String

    if let f = firstItem { firstItemString = f }
    else if let f = firstObject as? Named { firstItemString = f.name.camelCaseString }
    else { firstItemString = "firstItem" }

    result += "\(firstItemString).\(firstAttribute.rawValue) \(relation.rawValue)"

    if secondAttribute != .NotAnAttribute {
      let secondItemString: String
      if let s = secondItem { secondItemString = s }
      else if let s = secondObject as? Named { secondItemString = s.name.camelCaseString }
      else { secondItemString = "secondItem" }
      result += " \(secondItemString).\(secondAttribute.rawValue)"
    }

    if multiplier != 1.0 { result += " x \(multiplier)" }

    if constant != 0.0 { let sign = constant.isSignMinus ? "-" : "+"; result += " \(sign) \(abs(constant))" }
    if priority != UILayoutPriorityRequired { result += " @\(priority)" }

    return result
  }
}

// MARK: DebugPrintable

extension PseudoConstraint: CustomDebugStringConvertible {
  public var debugDescription: String {
    return "\n".join(description,
      "firstItem: \(String(prettyNil: firstItem))",
      "firstObject: \(String(prettyNil: firstObject))",
      "secondItem: \(String(prettyNil: secondItem))",
      "secondObject: \(String(prettyNil: secondObject))",
      "firstAttribute: \(firstAttribute.rawValue)",
      "secondAttribute: \(secondAttribute.rawValue)",
      "relation: \(relation.rawValue)",
      "multiplier: \(multiplier)",
      "constant: \(constant)",
      "identifier: \(identifier)",
      "priority: \(priority)")
  }
}

extension PseudoConstraint {

  // MARK: - PseudoConstraint.Attribute

  public enum Attribute: String {
    case Left                 = "left"
    case Right                = "right"
    case Leading              = "leading"
    case Trailing             = "trailing"
    case Top                  = "top"
    case Bottom               = "bottom"
    case Size                 = "size"
    case Width                = "width"
    case Height               = "height"
    case Center               = "center"
    case CenterX              = "centerX"
    case CenterY              = "centerY"
    case Baseline             = "baseline"
    case FirstBaseline        = "firstBaseline"
    case LeftMargin           = "leftMargin"
    case RightMargin          = "rightMargin"
    case LeadingMargin        = "leadingMargin"
    case TrailingMargin       = "trailingMargin"
    case TopMargin            = "topMargin"
    case BottomMargin         = "bottomMargin"
    case CenterWithinMargins  = "centerWithinMargins"
    case CenterXWithinMargins = "centerXWithinMargins"
    case CenterYWithinMargins = "centerYWithinMargins"
    case NotAnAttribute       = ""

    public var NSLayoutAttributeValue: NSLayoutAttribute {
      switch self {
        case .Left:                  return .Left
        case .Right:                 return .Right
        case .Leading:               return .Leading
        case .Trailing:              return .Trailing
        case .Top:                   return .Top
        case .Bottom:                return .Bottom
        case .Size:                  return .NotAnAttribute
        case .Width:                 return .Width
        case .Height:                return .Height
        case .Center:                return .NotAnAttribute
        case .CenterX:               return .CenterX
        case .CenterY:               return .CenterY
        case .Baseline:              return .Baseline
        case .FirstBaseline:         return .FirstBaseline
        case .LeftMargin:            return .LeftMargin
        case .RightMargin:           return .RightMargin
        case .LeadingMargin:         return .LeadingMargin
        case .TrailingMargin:        return .TrailingMargin
        case .TopMargin:             return .TopMargin
        case .BottomMargin:          return .BottomMargin
        case .CenterWithinMargins:   return .NotAnAttribute
        case .CenterXWithinMargins:  return .CenterXWithinMargins
        case .CenterYWithinMargins:  return .CenterYWithinMargins
        case .NotAnAttribute:        return .NotAnAttribute
      }
    }

    public var axis: UILayoutConstraintAxis { return NSLayoutAttributeValue.axis }

    public init(_ NSLayoutAttributeValue: NSLayoutAttribute) {
      switch NSLayoutAttributeValue {
        case .Left:                  self = .Left
        case .Right:                 self = .Right
        case .Leading:               self = .Leading
        case .Trailing:              self = .Trailing
        case .Top:                   self = .Top
        case .Bottom:                self = .Bottom
        case .Width:                 self = .Width
        case .Height:                self = .Height
        case .CenterX:               self = .CenterX
        case .CenterY:               self = .CenterY
        case .Baseline:              self = .Baseline
        case .FirstBaseline:         self = .FirstBaseline
        case .LeftMargin:            self = .LeftMargin
        case .RightMargin:           self = .RightMargin
        case .LeadingMargin:         self = .LeadingMargin
        case .TrailingMargin:        self = .TrailingMargin
        case .TopMargin:             self = .TopMargin
        case .BottomMargin:          self = .BottomMargin
        case .CenterXWithinMargins:  self = .CenterXWithinMargins
        case .CenterYWithinMargins:  self = .CenterYWithinMargins
        default:                     self = .NotAnAttribute
      }
    }
  }

  // MARK: - PseudoConstraint.Relation

  public enum Relation: String {
    case Equal              = "="
    case GreaterThanOrEqual = "≥"
    case LessThanOrEqual    = "≤"

    public var NSLayoutRelationValue: NSLayoutRelation {
      switch self {
        case .Equal:              return .Equal
        case .GreaterThanOrEqual: return .GreaterThanOrEqual
        case .LessThanOrEqual:    return .LessThanOrEqual
      }
    }

    public init(_ NSLayoutRelationValue: NSLayoutRelation) {
      switch NSLayoutRelationValue {
        case .GreaterThanOrEqual: self = .GreaterThanOrEqual
        case .LessThanOrEqual:    self = .LessThanOrEqual
        default:                  self = .Equal
      }
    }
  }
}

// MARK: - Function-related typealiases

public typealias ViewAttribute = (UIView, PseudoConstraint.Attribute)

// MARK: - Typealiases of convenience

public typealias Pseudo   = PseudoConstraint
public typealias Relation = PseudoConstraint.Relation
public typealias Axis     = UILayoutConstraintAxis

// MARK: - Private constants of convenience

private let Less    = Relation.LessThanOrEqual
private let Greater = Relation.GreaterThanOrEqual
private let Equal   = Relation.Equal

// MARK: - Superview/ancestor helper functions

func discernViewSuperview(obj1: AnyObject?, obj2: AnyObject?) -> (view: UIView, superview: UIView)? {
  if let view = obj1 as? UIView, superview = view.superview where obj2 === superview {
    return (view: view, superview: superview)
  } else if let view = obj2 as? UIView, superview = view.superview where obj1 === superview {
    return (view: view, superview: superview)
  } else {
    return nil
  }
}

func discernNearestAncestor(obj1: AnyObject?, _ obj2: AnyObject?) -> UIView? {
  switch (obj1, obj2) {
    case let (v1 as UIView, v2 as UIView): return v1.nearestCommonAncestorWithView(v2)
    case let (v as UIView, nil): return v.superview
    case let (nil, v as UIView): return v.superview
    default: return nil
  }
}

// MARK: - Identifier operator
infix operator --> {associativity left}

public func -->(var lhs:     Pseudo, rhs: String?) ->  Pseudo  { lhs.identifier = rhs; return lhs }
public func -->(    lhs:   [Pseudo], rhs: String?) -> [Pseudo] { return lhs.map {$0 --> rhs}      }
public func -->(    lhs: [[Pseudo]], rhs: String?) -> [Pseudo] { return lhs.flatMap {$0 --> rhs} }

public func -->(lhs:     Pseudo, rhs: Identifier?) ->  Pseudo  { return lhs --> rhs?.string }
public func -->(lhs:   [Pseudo], rhs: Identifier?) -> [Pseudo] { return lhs --> rhs?.string }
public func -->(lhs: [[Pseudo]], rhs: Identifier?) -> [Pseudo] { return lhs --> rhs?.string }

// MARK: - Priority operator
infix operator -!> {associativity left}

public func -!>(var lhs:     Pseudo, rhs: Float) -> Pseudo   { lhs.priority = rhs; return lhs   }
public func -!>(    lhs:   [Pseudo], rhs: Float) -> [Pseudo] { return lhs.map {$0 -!> rhs}      }
public func -!>(    lhs: [[Pseudo]], rhs: Float) -> [Pseudo] { return lhs.flatMap {$0 -!> rhs} }

// MARK: - Equal operator
infix operator => {precedence 160}

public func =>(lhs: ViewAttribute, rhs: ViewAttribute) -> Pseudo { return Pseudo(first: lhs, second: rhs) }
public func =>(lhs: ViewAttribute, rhs: Floatable) -> Pseudo { return Pseudo(pair: lhs, constant: rhs.FloatValue) }

// MARK: - GreaterThanOrEqual operator
infix operator ≥ {precedence 160}

public func ≥(lhs: ViewAttribute, rhs: ViewAttribute) -> Pseudo { return Pseudo(first: lhs, second: rhs, relation: Greater) }
public func ≥(lhs: ViewAttribute, rhs: Floatable) -> Pseudo { return Pseudo(pair: lhs, constant: rhs.FloatValue, relation: Greater) }

// MARK: - LessThanOrEqual operator
infix operator ≤ {precedence 160}

public func ≤(lhs: ViewAttribute, rhs: ViewAttribute) -> Pseudo { return Pseudo(first: lhs, second: rhs, relation: Less) }
public func ≤(lhs: ViewAttribute, rhs: Floatable) -> Pseudo { return Pseudo(pair: lhs, constant: rhs.FloatValue, relation: Less) }

// MARK: - Multiplication, division, and subtraction operators

public func *(var lhs: Pseudo, rhs: Floatable) -> Pseudo { lhs.multiplier =  rhs.FloatValue; return lhs }
public func +(var lhs: Pseudo, rhs: Floatable) -> Pseudo { lhs.constant   =  rhs.FloatValue; return lhs }
public func -(var lhs: Pseudo, rhs: Floatable) -> Pseudo { lhs.constant   = -rhs.FloatValue; return lhs }

// MARK: - Flush to superview left/top operator

public func |(lhs: Axis, rhs: UIView) -> Pseudo {
  assert(rhs.superview != nil, "operator requires a proper view hierarchy has been established")
  switch lhs {
    case .Horizontal: return rhs.left => rhs.superview!.left
    case .Vertical:   return rhs.top  => rhs.superview!.top
  }
}

// MARK: - Flush to superview right/bottom operator

public func |(lhs: UIView, rhs: Axis) -> Pseudo {
  precondition(lhs.superview != nil, "operator requires a proper view hierarchy has been established")
  switch rhs {
    case .Horizontal: return lhs.right => lhs.superview!.right
    case .Vertical:   return lhs.bottom => lhs.superview!.bottom
  }
}

public func |(lhs:   Pseudo, rhs: Axis) -> [Pseudo] { return [lhs]|rhs }
public func |(var lhs: [Pseudo], rhs: Axis) -> [Pseudo] {
  precondition(lhs.last?.firstObject as? UIView != nil, "operator requires a view for the last constraint's firstObject")
  let view = lhs.last!.firstObject as! UIView
  precondition(view.superview != nil, "operator requires a proper view hierarchy has been established")
  switch rhs {
    case .Horizontal: lhs.append(view.right => view.superview!.right)
    case .Vertical: lhs.append(view.bottom => view.superview!.bottom)
  }
  return lhs
}

// MARK: - Offset from superview left/top using standard margin
infix operator |- { associativity left precedence 140 }

public func |-(lhs: Axis, rhs: UIView) -> Pseudo {
  assert(rhs.superview != nil, "operator requires a proper view hierarchy has been established")
  switch lhs {
    case .Horizontal: return rhs.left => rhs.superview!.left + 20
    case .Vertical:   return rhs.top  => rhs.superview!.top + 20
  }
}

// MARK: - Offset from superview right/bottom using standard margin
infix operator -| { associativity left precedence 140 }

public func -|(lhs: UIView, rhs: Axis) -> Pseudo {
  precondition(lhs.superview != nil, "operator requires a proper view hierarchy has been established")
  switch rhs {
    case .Horizontal: return lhs.right => lhs.superview!.right - 20
    case .Vertical:   return lhs.bottom => lhs.superview!.bottom - 20
  }
}

public func -|(lhs:   Pseudo, rhs: Axis) -> [Pseudo] { return [lhs]-|rhs }
public func -|(var lhs: [Pseudo], rhs: Axis) -> [Pseudo] {
  precondition(lhs.last?.firstObject as? UIView != nil, "operator requires a view for the last constraint's firstObject")
  let view = lhs.last!.firstObject as! UIView
  precondition(view.superview != nil, "operator requires a proper view hierarchy has been established")
  switch rhs {
    case .Horizontal: lhs.append(view.right => view.superview!.right - 20)
    case .Vertical: lhs.append(view.bottom => view.superview!.bottom - 20)
  }
  return lhs
}

// MARK: - Offset from superview left/top operator
infix operator |-- {associativity left precedence 140}

public func |--(lhs: Axis, rhs: Floatable        ) -> (Axis, Float, Relation) { return (lhs, rhs.FloatValue, Equal) }
public func |--(lhs: Axis, rhs: (Float, Relation)) -> (Axis, Float, Relation) { return (lhs, rhs.0,          rhs.1) }

// MARK: - Offset from superview right/bottom operator
infix operator --| {associativity left precedence 140}

public func --|(lhs: (Pseudo, Float, Relation), rhs: Axis) -> [Pseudo] {
  if let (view, superview) = discernViewSuperview(lhs.0.firstObject, obj2: lhs.0.secondObject) {
    switch lhs.0.firstAttribute.axis {
      case .Horizontal:
        switch lhs.2 {
          case .Equal:              return [lhs.0, view.right => superview.right - lhs.1]
          case .GreaterThanOrEqual: return [lhs.0, view.right ≥  superview.right - lhs.1]
          case .LessThanOrEqual:    return [lhs.0, view.right ≤  superview.right - lhs.1]
        }
      case .Vertical:
        switch lhs.2 {
          case .Equal:              return [lhs.0, view.bottom => superview.bottom - lhs.1]
          case .GreaterThanOrEqual: return [lhs.0, view.bottom ≥  superview.bottom - lhs.1]
          case .LessThanOrEqual:    return [lhs.0, view.bottom ≤  superview.bottom - lhs.1]
        }
    }
  } else { return [] }

}

public func --|(lhs: ([Pseudo], Float, Relation), rhs: Axis) -> [Pseudo] {
  var superview: UIView?
  for constraint in lhs.0 {
    superview = discernNearestAncestor(discernNearestAncestor(constraint.firstObject, constraint.secondObject), superview)
  }
  precondition(superview != nil, "operator requires a proper view hierarchy has been established")
  if let lastConstraint = lhs.0.last, lastView = lastConstraint.firstObject as? UIView {
    precondition(lastConstraint.firstAttribute.axis == rhs, "axis miss-match")
    switch rhs {
      case .Horizontal:
        switch lhs.2 {
          case .Equal:              return lhs.0 + [lastView.right => superview!.right - lhs.1]
          case .GreaterThanOrEqual: return lhs.0 + [lastView.right ≥  superview!.right - lhs.1]
          case .LessThanOrEqual:    return lhs.0 + [lastView.right ≤  superview!.right - lhs.1]
        }
      case .Vertical:
        switch lhs.2 {
          case .Equal:              return lhs.0 + [lastView.bottom => superview!.bottom - lhs.1]
          case .GreaterThanOrEqual: return lhs.0 + [lastView.bottom ≥  superview!.bottom - lhs.1]
          case .LessThanOrEqual:    return lhs.0 + [lastView.bottom ≤  superview!.bottom - lhs.1]
        }
    }
  } else { return [] }

}

public func --|(lhs: (UIView, Float, Relation), rhs: Axis) -> Pseudo {
  precondition(lhs.0.superview != nil, "operator requires a proper view hierarchy has been established")
  switch rhs {
    case .Horizontal:
      switch lhs.2 {
        case .Equal:              return lhs.0.right => lhs.0.superview!.right - lhs.1
        case .GreaterThanOrEqual: return lhs.0.right ≥  lhs.0.superview!.right - lhs.1
        case .LessThanOrEqual:    return lhs.0.right ≤  lhs.0.superview!.right - lhs.1
      }
    case .Vertical:
      switch lhs.2 {
        case .Equal:              return lhs.0.bottom => lhs.0.superview!.bottom - lhs.1
        case .GreaterThanOrEqual: return lhs.0.bottom ≥  lhs.0.superview!.bottom - lhs.1
        case .LessThanOrEqual:    return lhs.0.bottom ≤  lhs.0.superview!.bottom - lhs.1
      }
  }
}

// MARK: - Spacing operator
// MARK:   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
infix operator -- {associativity left precedence 140}

// MARK: Prefix

public func --(lhs: [Pseudo], rhs: Floatable        ) -> ([Pseudo], Float, Relation) { return (lhs, rhs.FloatValue,  Equal) }
public func --(lhs:   Pseudo, rhs: Floatable        ) -> (  Pseudo, Float, Relation) { return (lhs, rhs.FloatValue,  Equal) }
public func --(lhs:   UIView, rhs: Floatable        ) -> (  UIView, Float, Relation) { return (lhs, rhs.FloatValue,  Equal) }
public func --(lhs: [Pseudo], rhs: (Float, Relation)) -> ([Pseudo], Float, Relation) { return (lhs, rhs.0,           rhs.1) }
public func --(lhs:   Pseudo, rhs: (Float, Relation)) -> (  Pseudo, Float, Relation) { return (lhs, rhs.0,           rhs.1) }
public func --(lhs:   UIView, rhs: (Float, Relation)) -> (  UIView, Float, Relation) { return (lhs, rhs.0,           rhs.1) }

// MARK: Resolution

public func --(lhs: UIView, rhs: UIView)   -> Pseudo   { return (  lhs, 8, Equal) -- rhs }
public func --(lhs: Pseudo, rhs: UIView)   -> [Pseudo] { return ([lhs], 8, Equal) -- rhs }
public func --(lhs: [Pseudo], rhs: UIView) -> [Pseudo] { return (  lhs, 8, Equal) -- rhs }

public func --(lhs: ([Pseudo], Float, Relation), rhs: UIView) -> [Pseudo] {
  var pseudoConstraints = lhs.0
  if let lastConstraint = pseudoConstraints.last, lastView = lastConstraint.firstObject as? UIView {
    switch lastConstraint.firstAttribute.axis {
      case .Horizontal:
        switch lhs.2 {
          case .Equal:              pseudoConstraints.append(rhs.left => lastView.right + lhs.1)
          case .GreaterThanOrEqual: pseudoConstraints.append(rhs.left ≥  lastView.right + lhs.1)
          case .LessThanOrEqual:    pseudoConstraints.append(rhs.left ≤  lastView.right + lhs.1)
        }
      case .Vertical:
        switch lhs.2 {
          case .Equal:              pseudoConstraints.append(rhs.top => lastView.bottom + lhs.1)
          case .GreaterThanOrEqual: pseudoConstraints.append(rhs.top ≥  lastView.bottom + lhs.1)
          case .LessThanOrEqual:    pseudoConstraints.append(rhs.top ≤  lastView.bottom + lhs.1)
        }

    }
    return pseudoConstraints
  } else { assert(false, "at least one existing constraint with valid first object") }
}

public func --(lhs: (Axis, Float, Relation), rhs: UIView) -> Pseudo {
  precondition(rhs.superview != nil, "operator requires a proper view hierarchy has been established")
  switch lhs.0 {
    case .Horizontal:
      switch lhs.2 {
        case .Equal:              return rhs.left => rhs.superview!.left + lhs.1
        case .GreaterThanOrEqual: return rhs.left ≥  rhs.superview!.left + lhs.1
        case .LessThanOrEqual:    return rhs.left ≤  rhs.superview!.left + lhs.1
      }

    case .Vertical:
      switch lhs.2 {
        case .Equal:              return rhs.top => rhs.superview!.top + lhs.1
        case .GreaterThanOrEqual: return rhs.top ≥  rhs.superview!.top + lhs.1
        case .LessThanOrEqual:    return rhs.top ≤  rhs.superview!.top + lhs.1
      }

  }
}

public func --(lhs: (Pseudo, Float, Relation), rhs: UIView) -> [Pseudo] { return ([lhs.0], lhs.1, lhs.2) -- rhs }
public func --(lhs: (UIView, Float, Relation), rhs: UIView) -> Pseudo {
  switch lhs.2 {
    case .Equal:              return rhs.left => lhs.0.right + lhs.1
    case .GreaterThanOrEqual: return rhs.left ≥  lhs.0.right + lhs.1
    case .LessThanOrEqual:    return rhs.left ≤  lhs.0.right + lhs.1
  }
}

// MARK: - GreaterThanOrEqual spacing prefix operator
prefix operator ≥ {}

public prefix func ≥(value: Floatable) -> (Float, Relation) { return (value.FloatValue, Greater) }

// MARK: - LessThanOrEqual spacing prefix operator
prefix operator ≤ {}

public prefix func ≤(value: Floatable) -> (Float, Relation) { return (value.FloatValue, Less) }
