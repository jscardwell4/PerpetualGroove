//
//  UIView+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/14/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

private let identifierKey = UnsafePointer<Void>()

public extension UIView {

  @IBInspectable public var identifier: String? {
    get { return objc_getAssociatedObject(self, identifierKey) as? String }
    set { objc_setAssociatedObject(self, identifierKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
  }

  public var viewTreeDescription: String { return viewTreeDescriptionWithProperties() }

  /**
  viewTreeDescriptionWithProperties:

  - parameter properties: String ...

  - returns: String
  */
  public func viewTreeDescriptionWithProperties(properties: String ...) -> String {

    var result = ""

    /**
    Helper to recursively process view hierarchy

    - parameter view: UIView
    - parameter indent: Int
    */
    func dumpView(view: UIView, indent: Int) {

      result += "-" * (indent * 2)

      var propertyValues: [String:String] = [:]

      for property in properties {
        let value: AnyObject?
        switch view.respondsToSelector(NSSelectorFromString(property)) {
          case true: value = view.valueForKey(property)
          case false where property.characters.contains("."): value = view.valueForKeyPath(property)
          case false: continue
        }

        guard value != nil
           && (!value!.respondsToSelector("count") || value!.valueForKey("count") as! Int != 0) else { continue }

        propertyValues[property] = String(value)
      }

      let propertyValuesString = "\n".join(propertyValues.map({"\($0): \($1)"}))
      let depthString = "[" + String(indent).pad(" ", count: 2, type: .Prefix) + "] "
      let classString = "\(view.dynamicType.self)"
      let addressString = "(\(unsafeAddressOf(view)))"
      var viewString = depthString + classString + addressString
      if let identifier = view.identifier { viewString += "<'\(identifier)'>" }
      if !propertyValuesString.isEmpty { viewString += ":\n" + propertyValuesString.indentedBy(2 * (indent + 1)) }
      viewString += "\n"
      result += viewString
      for subview in view.subviews { dumpView(subview, indent: indent + 1) }
    }

    dumpView(self, indent: 0)

    return result
  }

  public var snapshot: UIImage {
    UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
    drawViewHierarchyInRect(bounds, afterScreenUpdates: false)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }

  /**
  blurredSnapshotWithRadius:tintColor:saturationDeltaFactor:maskImage:

  - parameter radius: CGFloat
  - parameter tintColor: UIColor
  - parameter factor: CGFloat
  - parameter maskImage: UIImage?

  - returns: UIImage
  */
  public func blurredSnapshotWithRadius(radius: CGFloat = 3,
                    tintColor: UIColor = UIColor(white: 1.0, alpha: 0.5),
        saturationDeltaFactor factor: CGFloat = 1,
                    maskImage: UIImage? = nil) -> UIImage
  {
    return snapshot.applyBlurWithRadius(radius,
                              tintColor: tintColor,
                  saturationDeltaFactor: factor,
                              maskImage: maskImage)
  }

  // MARK: - Initializers

  /**
  initWithAutolayout:

  - parameter autolayout: Bool
  */
  public convenience init(autolayout: Bool) {
    self.init(frame: CGRect.zero)
    translatesAutoresizingMaskIntoConstraints = !autolayout
  }

  // MARK: - Descriptions

  /**
  framesDescription

  - returns: String
  */
  public var framesDescription: String {
  	return viewTreeDescriptionWithProperties("frame")
      .stringByReplacingRegEx("[{]\\s*\n\\s*frame = \"NSRect:\\s*([^\"]+)\";\\s*\n\\s*[}]",
                   withString: " { frame=$1 }")
  }

  /**
  descriptionTree:

  - parameter properties: String ...

  - returns: String
  */
//  public func descriptionTree(properties: String ...) -> String {
//  	return viewTreeDescriptionWithProperties(properties)
//  }

  /**
  recursiveConstraintsDescription

  - returns: String
  */
  public func recursiveConstraintsDescription() -> String {
    var result = ""
    if let identifier = identifier {
      result += "<\(className)(\(identifier)):\(unsafeAddressOf(self))>"
    } else {
      result += "<\(className):\(unsafeAddressOf(self))>"
    }
    result += " {\n\t"
    result += "\n\t".join(constraints.map { $0.prettyDescription })
    let subviewsConstraints = subviews.map { $0.recursiveConstraintsDescription().indentedBy(8) }
    if subviewsConstraints.count > 0 { result += "\n" + "\n".join(subviewsConstraints) }
    result += "\n}"
    return result
  }

  // MARK: - Subscripts

  /**
  subscript:

  - parameter nametag: String

  - returns: UIView?
  */
  public subscript(nametag: String) -> UIView? { return subviews.filter({$0.identifier == nametag}).first }

  // MARK: - Ancestors

  /**
  nearestCommonAncestorWithView:

  - parameter view: UIView

  - returns: UIView?
  */
  public func nearestCommonAncestorWithView(view: UIView) -> UIView? {
    var ancestor: UIView? = nil
    var ancestors = Set<UIView>()
    var v: UIView? = self
    while v != nil { ancestors.insert(v!); v = v!.superview }
    v = view
    while v != nil { if ancestors.contains(v!) { ancestor = v; break } else { v = v!.superview } }
    return ancestor
  }

  // MARK: - Subviews

  /**
  subviewsOfKind:

  - parameter kind: T.Type

  - returns: [T]
  */
  public func subviewsOfKind<T:UIView>(kind: T.Type) -> [T] { return subviews.compressedMap({$0 as? T}) }

  /**
  firstSubviewOfKind:

  - parameter kind: T.Type

  - returns: T?
  */
  public func firstSubviewOfKind<T:UIView>(kind: T.Type) -> T? { return findFirst(subviews, {$0 as? T != nil}) as? T }

  /**
  subviewsOfType:

  - parameter type: T.Type

  - returns: [T]
  */
  public func subviewsOfType<T:UIView>(type: T.Type) -> [T] {
    let filtered = subviews.filter { (s:AnyObject) -> Bool in return s.dynamicType.self === T.self }
    return filtered.map {$0 as! T}
  }

  /**
  firstSubviewOfType:

  - parameter type: T.Type

  - returns: T?
  */
  public func firstSubviewOfType<T:UIView>(type: T.Type) -> T? {
    return findFirst(subviews, {(s:AnyObject) -> Bool in return s.dynamicType.self === T.self}) as? T
  }

  /**
  subviewsMatching:

  - parameter predicate: NSPredicate

  - returns: [UIView]
  */
  @objc(subviewsMatchingPredicate:)
  public func subviewsMatching(predicate: NSPredicate) -> [UIView] {
    return subviews.filter({(s:AnyObject) -> Bool in return predicate.evaluateWithObject(s)}) as [UIView]
  }

  /**
  firstSubviewMatching:

  - parameter predicate: NSPredicate

  - returns: UIView?
  */
  @objc(firstSubviewMatchingPredicate:)
  public func firstSubviewMatching(predicate: NSPredicate) -> UIView? {
    return findFirst(subviews, {(s:AnyObject) -> Bool in return predicate.evaluateWithObject(s)})
  }

  /**
  subviewsMatching:

  - parameter predicate: (AnyObject) -> Bool

  - returns: [UIView]
  */
  public func subviewsMatching(predicate: (AnyObject) -> Bool) -> [UIView] {
    return subviews.filter(predicate) as [UIView]
  }

  /**
  firstSubviewMatching:

  - parameter predicate: (AnyObject) -> Bool

  - returns: UIView?
  */
  public func firstSubviewMatching(predicate: (AnyObject) -> Bool) -> UIView? {
    return findFirst(subviews, predicate)
  }

  /**
  subviewsWithIdentifier:

  - parameter id: String

  - returns: [UIView]
  */
  public func subviewsWithIdentifier(id: String) -> [UIView] {
    return subviewsMatching(∀"self.identifier == '\(id)'")
  }

  /**
  subviewsWithIdentiferPrefix:

  - parameter prefix: String

  - returns: [UIView]
  */
  public func subviewsWithIdentiferPrefix(prefix: String) -> [UIView] {
    return subviewsMatching(∀"self.identifier beginsWith '\(prefix)'")
  }

  /**
  subviewsWithIdentiferSuffix:

  - parameter suffix: String

  - returns: [UIView]
  */
  public func subviewsWithIdentiferSuffix(suffix: String) -> [UIView] {
    return subviewsMatching(∀"self.identifier endsWith '\(suffix)'")
  }

  // MARK: - Existing constraints

  /**
  constraintsWithIdentifierTag:

  - parameter tag: String

  - returns: [NSLayoutConstraint]
  */
  public func constraintsWithIdentifierTag(tag: String) -> [NSLayoutConstraint] {
    return constraints.filter { Identifier($0.identifier) ∋ tag }
  }

  /**
  constraintsWithIdentifier:

  - parameter identifier: Identifier

  - returns: [NSLayoutConstraint]
  */
  public func constraintsWithIdentifier(identifier: Identifier) -> [NSLayoutConstraint] {
    return constraints.filter { $0.identifier == identifier.string }
  }

  /**
  constraintsWithTag:

  - parameter tag: Identifier.Tag

  - returns: [NSLayoutConstraint]
  */
  @nonobjc public func constraintsWithTag(tag: Identifier.Tag) -> [NSLayoutConstraint] {
    return constraints.filter {
      guard let id = $0.identifier else { return false }
      return Identifier(id) ∋ tag
    }
  }

  /**
  constraintsWithTags:

  - parameter tags: [Identifier.Tag]

  - returns: [NSLayoutConstraint]
  */
  public func constraintsWithTags(tags: [Identifier.Tag]) -> [NSLayoutConstraint] {
    return constraints.filter {
      guard let id = $0.identifier else { return false }
      return Set(Identifier(id)) ⊇ tags
    }
  }
  /**
  constraintsWithPrefixTag:

  - parameter tag: Identifier.Tag

  - returns: [NSLayoutConstraint]
  */
  public func constraintsWithPrefixTag(tag: Identifier.Tag) -> [NSLayoutConstraint] {
    return constraints.filter {
      guard let id = $0.identifier else { return false }
      return Identifier(id).first == tag
    }
  }

  /**
  constraintsWithPrefixTags:

  - parameter tags: [Identifier.Tag]

  - returns: [NSLayoutConstraint]
  */
  public func constraintsWithPrefixTags(tags: [Identifier.Tag]) -> [NSLayoutConstraint] {
    return constraints.filter {
      guard let id = $0.identifier else { return false }
      return Identifier(id).startsWith(tags)
    }
  }

  /**
  constraintsWithSuffixTag:

  - parameter tag: Identifier.Tag

  - returns: [NSLayoutConstraint]
  */
  public func constraintsWithSuffixTag(tag: Identifier.Tag) -> [NSLayoutConstraint] {
    return constraints.filter {
      guard let id = $0.identifier else { return false }
      return Identifier(id).last == tag
    }
  }

  /**
  constraintsWithSuffixTags:

  - parameter tags: [Identifier.Tag]

  - returns: [NSLayoutConstraint]
  */
  public func constraintsWithSuffixTags(tags: [Identifier.Tag]) -> [NSLayoutConstraint] {
    return constraints.filter {
      guard let id = $0.identifier else { return false }
      return Identifier(id).reverse().startsWith(tags.reverse())
    }
  }

  /**
  constraintWithIdentifierTag:

  - parameter tag: String

  - returns: NSLayoutConstraint?
  */
  public func constraintWithIdentifierTag(tag: String) -> NSLayoutConstraint? {
    return constraintsWithIdentifierTag(tag).first
  }

  /**
  constraintWithIdentifier:

  - parameter identifier: Identifier

  - returns: NSLayoutConstraint?
  */
  public func constraintWithIdentifier(identifier: Identifier) -> NSLayoutConstraint? {
    return constraintsWithIdentifier(identifier).first
  }

  /**
  constraintWithTag:

  - parameter tag: Identifier.Tag

  - returns: NSLayoutConstraint?
  */
  @nonobjc public func constraintWithTag(tag: Identifier.Tag) -> NSLayoutConstraint? {
    return constraintsWithTag(tag).first
  }

  /**
  constraintWithTags:

  - parameter tags: [Identifier.Tag]

  - returns: NSLayoutConstraint?
  */
  public func constraintWithTags(tags: [Identifier.Tag]) -> NSLayoutConstraint? {
    return constraintsWithTags(tags).first
  }
  
  /**
  constraintWithPrefixTag:

  - parameter tag: Identifier.Tag

  - returns: NSLayoutConstraint?
  */
  public func constraintWithPrefixTag(tag: Identifier.Tag) -> NSLayoutConstraint? {
    return constraintsWithPrefixTag(tag).first
  }

  /**
  constraintWithPrefixTags:

  - parameter tags: [Identifier.Tag]

  - returns: NSLayoutConstraint?
  */
  public func constraintWithPrefixTags(tags: [Identifier.Tag]) -> NSLayoutConstraint? {
    return constraintsWithPrefixTags(tags).first
  }

  /**
  constraintWithSuffixTag:

  - parameter tag: Identifier.Tag

  - returns: NSLayoutConstraint?
  */
  public func constraintWithSuffixTag(tag: Identifier.Tag) -> NSLayoutConstraint? {
    return constraintsWithSuffixTag(tag).first
  }

  /**
  constraintWithSuffixTags:

  - parameter tags: [Identifier.Tag]

  - returns: NSLayoutConstraint?
  */
  public func constraintWithSuffixTags(tags: [Identifier.Tag]) -> NSLayoutConstraint? {
    return constraintsWithSuffixTags(tags).first
  }

  // MARK: - PseudoConstraint helpers

  public var right:    (UIView, PseudoConstraint.Attribute) { return (self, .Right   ) }
  public var left:     (UIView, PseudoConstraint.Attribute) { return (self, .Left    ) }
  public var top:      (UIView, PseudoConstraint.Attribute) { return (self, .Top     ) }
  public var bottom:   (UIView, PseudoConstraint.Attribute) { return (self, .Bottom  ) }
  public var centerX:  (UIView, PseudoConstraint.Attribute) { return (self, .CenterX ) }
  public var centerY:  (UIView, PseudoConstraint.Attribute) { return (self, .CenterY ) }
  public var width:    (UIView, PseudoConstraint.Attribute) { return (self, .Width   ) }
  public var height:   (UIView, PseudoConstraint.Attribute) { return (self, .Height  ) }
  public var baseline: (UIView, PseudoConstraint.Attribute) { return (self, .Baseline) }
  public var leading:  (UIView, PseudoConstraint.Attribute) { return (self, .Leading ) }
  public var trailing: (UIView, PseudoConstraint.Attribute) { return (self, .Trailing) }

  // MARK: - Adding constraints

  /**
  constrain:views:identifier:

  - parameter format: String
  - parameter views: [String AnyObject]? = nil
  - parameter identifier: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func constrain(format: String, views: [String:AnyObject]? = nil, identifier: String? = nil) -> [NSLayoutConstraint] {
    if format.isEmpty { return [] }

    var dict: [String:AnyObject] = views ?? [:]
    dict["self"] = self

    let constraints = NSLayoutConstraint.constraintsByParsingFormat(format, views: dict)
    apply(constraints){$0.identifier = identifier}
    addConstraints(constraints)
    return constraints
  }

  /**
  constrain:

  - parameter pseudo: Pseudo...

  - returns: [NSLayoutConstraint]
  */
  public func constrain(pseudo: Pseudo...) -> [NSLayoutConstraint] { return _constrain(true, id: nil, pseudo: [pseudo]) }

  /**
  constrain:

  - parameter pseudo: [Pseudo]...

  - returns: [NSLayoutConstraint]
  */
  public func constrain(pseudo: [Pseudo]...) -> [NSLayoutConstraint] { return _constrain(true, id: nil, pseudo: pseudo) }

  /**
  constrain:identifier:pseudo:

  - parameter selfAsSuperview: Bool = true
  - parameter id: String? = nil
  - parameter pseudo: Array<PseudoConstraint> ...

  - returns: [NSLayoutConstraint]
  */
  public func constrain(selfAsSuperview: Bool = true,
             identifier id: String? = nil,
                      _ pseudo: Array<PseudoConstraint> ...) -> [NSLayoutConstraint]
  {
    return _constrain(selfAsSuperview, id: id, pseudo: pseudo)
  }

  /**
  constrain:identifier:pseudo:

  - parameter selfAsSuperview: Bool = true
  - parameter id: String? = nil
  - parameter pseudo: PseudoConstraint ...

  - returns: [NSLayoutConstraint]
  */
  public func constrain(selfAsSuperview: Bool = true, identifier id: String? = nil, _ pseudo: PseudoConstraint ...) -> [NSLayoutConstraint] {
    return _constrain(selfAsSuperview, id: id, pseudo: [pseudo])
  }


  /**
  _constrain:id:pseudo:

  - parameter selfAsSuperview: Bool
  - parameter id: String?
  - parameter pseudo: [[PseudoConstraint]]

  - returns: [NSLayoutConstraint]
  */
  private func _constrain(selfAsSuperview: Bool, id: String?, pseudo: [[PseudoConstraint]]) -> [NSLayoutConstraint] {
    var constraints: [PseudoConstraint] = pseudo.flatMap {$0}

    // If `selfAsSuperview` is `true` then process the constraints to make sure the deepest ancestor is the view
    if selfAsSuperview {
      // Find the deepest ancestor shared by all constraint objects
      var deepestAncestor: UIView?
      for constraint in constraints {
        let ancestor = discernNearestAncestor(constraint.firstObject, constraint.secondObject)
        switch (ancestor, deepestAncestor) {
        case let (a, d) where d == nil && a != nil:
          deepestAncestor = a
        case let (a, d) where a != nil && d != nil && !a!.isDescendantOfView(d!):
          if let v = discernNearestAncestor(a, d) { deepestAncestor = v }
          else { logWarning("unsupported constraint configuration, all objects must share a common ancestor"); return [] }
        default:
          break
        }
      }

      // If `deepestAncestor` is nil then most likely the array was empty, return an empty array just to be safe
      if deepestAncestor == nil { return [] }

        // Check if we are not the ancestor but the ancestor descends from us, if so then replace ancestor with self
        // unless both the first and second objects are the ancestor
      else if let ancestor = deepestAncestor where self != ancestor && ancestor.isDescendantOfView(self) {
        constraints = constraints.map {
          (var c: PseudoConstraint) -> PseudoConstraint in
          if c.firstObject === ancestor && c.secondObject !== ancestor { c.firstObject = self }
          else if c.secondObject === ancestor && c.firstObject !== ancestor { c.secondObject = self }
          return c
        }
      }

    }

    let result = constraints.flatMap({$0.expanded}).compressedMap({$0.constraint})// ➤| {if id != nil { $0.identifier = id }}
    if let id = id { result.forEach { $0.identifier = id } }
    //    let result = constraints.flatMap({$0.expanded}).compressedMap({$0.constraint}) ➤| {if id != nil { $0.identifier = id }}
    addConstraints(result)
    return result
  }

  // MARK: Sizing

  /**
  constrainSize:identifier:

  - parameter size: CGSize
  - parameter id: String? = nil

  - returns: (w: NSLayoutConstraint, h: NSLayoutConstraint)
  */
  public func constrainSize(size: CGSize, identifier id: String? = nil) -> (w: NSLayoutConstraint, h: NSLayoutConstraint) {
    return (w: constrainWidth(Float(size.width), identifier: id), h: constrainHeight(Float(size.height), identifier: id))
  }

  /**
  constrainWidth:identifier:

  - parameter width: Float
  - parameter id: String? = nil

  - returns: NSLayoutConstraint
  */
  public func constrainWidth(width: Float, identifier id: String? = nil) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint(self.width => abs(width) --> id)
    addConstraint(constraint)
    return constraint
  }

  /**
  constrainHeight:identifier:

  - parameter height: Float
  - parameter id: String? = nil

  - returns: NSLayoutConstraint
  */
  public func constrainHeight(height: Float, identifier id: String? = nil) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint(self.height => abs(height) --> id)
    addConstraint(constraint)
    return constraint
  }

  /**
  constrainAspect:identifier:

  - parameter aspect: Float
  - parameter id: String? = nil

  - returns: NSLayoutConstraint
  */
  public func constrainAspect(aspect: Float, identifier id: String? = nil) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint(self.width => self.height * aspect --> id)
    addConstraint(constraint)
    return constraint
  }

  // MARK: Insetting

  /**
  insetSubview:insets:identifier:

  - parameter subview: UIView
  - parameter insets: UIEdgeInsets
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func insetSubview(subview: UIView, insets: UIEdgeInsets, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    let (top, left, bottom, right) = insets.unpack
    return constrain(identifier: id,
                     subview.left => self.left + Float(left),
                     subview.right => self.right - Float(right),
                     subview.top => self.top + Float(top),
                     subview.bottom => self.bottom - Float(bottom))
  }

  // MARK: Stretching

  /**
  stretchSubview:

  - parameter subview: UIView
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func stretchSubview(subview: UIView, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return horizontallyStretchSubview(subview, identifier: id) + verticallyStretchSubview(subview, identifier: id)
  }

  /**
  horizontallyStretchSubview:identifier:

  - parameter subview: UIView
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func horizontallyStretchSubview(subview: UIView, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.left => self.left, subview.right => self.right)
  }

  /**
  verticallyStretchSubview:identifier:

  - parameter subview: UIView
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func verticallyStretchSubview(subview: UIView, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.top => self.top, subview.bottom => self.bottom)
  }

  /**
  stretchSubview:toSubview:identifier:

  - parameter s1: UIView
  - parameter s2: UIView
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func stretchSubview(s1: UIView, toSubview s2: UIView, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !((subviews as [UIView]) ⊃ [s1, s2]) { return [] }
    return constrain(identifier: id, s1.left => s2.left, s1.right => s2.right, s1.top => s2.top, s1.bottom => s2.bottom)
  }

  // MARK: Centering

  /**
  horizontallyCenterSubview:offset:identifier:

  - parameter subview: UIView
  - parameter offset: Float = 0.0
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func horizontallyCenterSubview(subview: UIView,
                                 offset: Float = 0.0,
                             identifier id: String? = nil) -> [NSLayoutConstraint]
  {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.centerX => self.centerX + offset)
  }

  /**
  verticallyCenterSubview:offset:identifier:

  - parameter subview: UIView
  - parameter offset: Float = 0.0
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func verticallyCenterSubview(subview: UIView,
                               offset: Float = 0.0,
                           identifier id: String? = nil) -> [NSLayoutConstraint]
  {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.centerY => self.centerY + offset)
  }

  /**
  centerSubview:offset:identifier:

  - parameter subview: UIView
  - parameter offset: Float = 0.0
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func centerSubview(subview: UIView, offset: Float = 0.0, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.centerX => self.centerX + offset, subview.centerY => self.centerY + offset)
  }

  // MARK: Aligning

  /**
  leftAlignSubview:offset:identifier:

  - parameter subview: UIView
  - parameter offset: Float = 0.0
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func leftAlignSubview(subview: UIView, offset: Float = 0.0, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.left => self.left + offset)
  }

  /**
  rightAlignSubview:offset:identifier:

  - parameter subview: UIView
  - parameter offset: Float = 0.0
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func rightAlignSubview(subview: UIView, offset: Float = 0.0, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.right => self.right + offset)
  }

  /**
  topAlignSubview:offset:identifier:

  - parameter subview: UIView
  - parameter offset: Float = 0.0
  - parameter identifier: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func topAlignSubview(subview: UIView, offset: Float = 0.0, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.top => self.top + offset)
  }

  /**
  bottomAlignSubview:offset:identifier:

  - parameter subview: UIView
  - parameter offset: Float = 0.0
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func bottomAlignSubview(subview: UIView, offset: Float = 0.0, identifier id: String? = nil) -> [NSLayoutConstraint] {
    if !subview.isDescendantOfView(self) { return [] }
    return constrain(identifier: id, subview.bottom => self.bottom + offset)
  }

  /**
  alignSubview:besideSubview:offset:identifier:

  - parameter s1: UIView
  - parameter s2: UIView
  - parameter offset: Float
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func alignSubview(s1: UIView,
             besideSubview s2: UIView,
                    offset: Float,
                identifier id: String? = nil) -> [NSLayoutConstraint]
  {
    if !((subviews as [UIView]) ⊃ [s1, s2]) { return [] }
    return constrain(identifier: id, s2.left => s1.right + offset)
  }

  /**
  alignSubview:aboveSubview:offset:identifier:

  - parameter s1: UIView
  - parameter s2: UIView
  - parameter offset: Float
  - parameter id: String? = nil

  - returns: [NSLayoutConstraint]
  */
  public func alignSubview(s1: UIView,
              aboveSubview s2: UIView,
                    offset: Float,
                identifier id: String? = nil) -> [NSLayoutConstraint]
  {
    if !((subviews as [UIView]) ⊃ [s1, s2]) { return [] }
    return constrain(identifier: id, s2.top => s1.bottom + offset)
  }

}
