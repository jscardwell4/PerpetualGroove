//
//  PopoverView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/22/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

@IBDesignable public class PopoverView: UIView {

  /** Enumeration to define which edge of the view will have an arrow */
  public enum Location: String { case Top, Bottom }

  /** Whether the arrow is drawn at the top or the bottom of the view, also affects label offsets and alignment rect */
  public var location: Location = .Bottom {
    didSet {
      guard oldValue != location else { return }
      refreshShape()
      removeConstraints(constraintsWithIdentifier(constraintID))
      setNeedsUpdateConstraints()
    }
  }
  @IBInspectable public var locationString: String {
    get { return location.rawValue }
    set { if let location = Location(rawValue: newValue) { self.location = location }  }
  }

  /** Value used to size the arrow's width */
  @IBInspectable public var arrowWidth: CGFloat = 10  { didSet { refreshShape() } }

  /** Value used to size the arrow's height */
  @IBInspectable public var arrowHeight: CGFloat = 10  { didSet { refreshShape() } }

  /** Value used to place arrow */
  @IBInspectable public var xOffset: CGFloat = 0 { didSet { refreshShape() } }


  /** Padding for the content view */
  public var contentInsets = UIEdgeInsets(inset: 10) {
    didSet {
      guard contentInsets != oldValue else { return }
      invalidateIntrinsicContentSize()
      removeConstraints(constraintsWithIdentifier(Identifier(self, "Content")))
      setNeedsUpdateConstraints()
    }
  }

  /**
  intrinsicConltentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    var size = contentView.intrinsicContentSize()
    for subview in contentView.subviews {
      let subviewIntrinsicContentSize = subview.intrinsicContentSize()
      size.width = max(size.width, subviewIntrinsicContentSize.width)
      size.height = max(size.height, subviewIntrinsicContentSize.height)
    }
    return size + contentInsets.displacement
  }

  /**
  Overridden to account for the top/bottom arrow

  - returns: UIEdgeInsets
  */
  public override func alignmentRectInsets() -> UIEdgeInsets {
    switch location {
      case .Top:    return UIEdgeInsets(top: arrowHeight, left: 0, bottom: 0, right: 0)
      case .Bottom: return UIEdgeInsets(top: 0, left: 0, bottom: arrowHeight, right: 0)
    }
  }

  /** Method for updating the shape layer's path according to the views `bounds` and `location` */
  private func refreshShape() {
    let (w, h) = bounds.size.unpack
    guard w > arrowWidth && h > arrowHeight else { return }

    let mid = round(half(w) + xOffset)
    let arrowWidth_2 = arrowWidth / 2
    let path = UIBezierPath()

    switch location {
      case .Top:
        path.moveToPoint   (CGPoint(x: 0,                     y: arrowHeight    ))
        path.addLineToPoint(CGPoint(x: mid - arrowWidth_2,    y: arrowHeight    ))
        path.addLineToPoint(CGPoint(x: mid,                   y: 0              ))
        path.addLineToPoint(CGPoint(x: mid + arrowWidth_2,    y: arrowHeight    ))
        path.addLineToPoint(CGPoint(x: w,                     y: arrowHeight    ))
        path.addLineToPoint(CGPoint(x: w,                     y: h              ))
        path.addLineToPoint(CGPoint(x: 0,                     y: h              ))
      case .Bottom:
        path.moveToPoint   (CGPoint(x: 0,                     y: 0              ))
        path.addLineToPoint(CGPoint(x: w,                     y: 0              ))
        path.addLineToPoint(CGPoint(x: w,                     y: h - arrowHeight))
        path.addLineToPoint(CGPoint(x: mid + arrowWidth_2,    y: h - arrowHeight))
        path.addLineToPoint(CGPoint(x: mid,                   y: h              ))
        path.addLineToPoint(CGPoint(x: mid - arrowWidth_2,    y: h - arrowHeight))
        path.addLineToPoint(CGPoint(x: 0,                     y: h - arrowHeight))
    }

    path.closePath()

    maskingLayer.frame = CGRect(size: bounds.size)
    maskingLayer.path = path.CGPath
  }


  /** Overridden so we can update our shape's path on bounds changes */
  public override var bounds: CGRect { didSet { refreshShape() } }

  /** Subview for holding the popover's content */
  @IBOutlet public private(set) weak var contentView: UIView!

  /** Convenience accessor for the shape layer used to mask root layer */
  private var maskingLayer: CAShapeLayer { return layer.mask as! CAShapeLayer }

  /** initializeIVARs */
  func initializeIVARs() {
    translatesAutoresizingMaskIntoConstraints = false

    layer.mask = CAShapeLayer()
    refreshShape()

    let contentView = UIView(autolayout: true)
    contentView.backgroundColor = .clearColor()
    addSubview(contentView)
    self.contentView = contentView
  }

  private let constraintID = Identifier("PopoverView", "Content")

  /** updateConstraints */
  public override func updateConstraints() {
    super.updateConstraints()

    guard constraintsWithIdentifier(constraintID).count == 0 else { return }

    let topOffset:    CGFloat = location == .Top    ? arrowHeight : 0
    let bottomOffset: CGFloat = location == .Bottom ? arrowHeight : 0
    constrain([𝗩|--(contentInsets.top - topOffset)--contentView--(contentInsets.bottom + bottomOffset)--|𝗩,
               𝗛|--contentInsets.left--contentView--contentInsets.right--|𝗛] --> constraintID)
  }

  /**
  requiresConstraintBasedLayout

  - returns: Bool
  */
  public override class func requiresConstraintBasedLayout() -> Bool { return true }

  /**
  initWithLabelData:dismissal:

  - parameter labelData: [LabelData]
  - parameter callback: ((PopoverView) -> Void
  */
  public override init(frame: CGRect) { super.init(frame: frame); initializeIVARs() }

  /** layoutSubviews */
  public override func layoutSubviews() { super.layoutSubviews(); refreshShape() }


  public override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    initializeIVARs()
  }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeDouble(Double(arrowWidth), forKey: "arrowWidth")
    aCoder.encodeDouble(Double(arrowHeight), forKey: "arrowHeight")
    aCoder.encodeDouble(Double(xOffset), forKey: "xOffset")
    aCoder.encodeUIEdgeInsets(contentInsets, forKey: "contentInsets")
    aCoder.encodeObject(location.rawValue, forKey: "location")
  }

  /**
  Initialization with coder is unsupported

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    arrowWidth = CGFloat(aDecoder.decodeDoubleForKey("arrowWidth"))
    arrowHeight = CGFloat(aDecoder.decodeDoubleForKey("arrowHeight"))
    xOffset = CGFloat(aDecoder.decodeDoubleForKey("xOffset"))
    contentInsets = aDecoder.decodeUIEdgeInsetsForKey("contentInsets")
    location = Location(rawValue: aDecoder.decodeObjectForKey("location") as? String ?? Location.Bottom.rawValue)!
    initializeIVARs()
  }

}
