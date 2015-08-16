//
//  PopoverView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/22/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

public class PopoverView: UIView {

  /** Enumeration to define which edge of the view will have an arrow */
  public enum Location { case Top, Bottom }

  /** Whether the arrow is drawn at the top or the bottom of the view, also affects label offsets and alignment rect */
  public var location: Location = .Bottom

  /** Value used to size the arrow's width */
  public var arrowWidth: CGFloat = 10  { didSet { refreshShape() } }

  /** Value used to size the arrow's height */
  public var arrowHeight: CGFloat = 10  { didSet { refreshShape() } }

  /** Value used to place arrow */
  public var xOffset: CGFloat = 0 { didSet { refreshShape() } }

  /** Optional callback for when popover is dismissed by touching outside it's bounds */
  private let dismissal: ((PopoverView) -> Void)?

  /** Whether to automatically generate a blurred snapshot of the window if `backdrop` is nil */
  public var blur = true

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

  /** Holds a reference to the effect view's content view */
  public weak var contentView: UIView!

  /** Convenience accessor for the shape layer used to mask root layer */
  private var maskingLayer: CAShapeLayer { return layer.mask as! CAShapeLayer }

  /** initializeIVARs */
  func initializeIVARs() {
    translatesAutoresizingMaskIntoConstraints = false

    layer.mask = CAShapeLayer()
    refreshShape()

    let blurEffect = UIBlurEffect(style: .Dark)
    let blur = UIVisualEffectView(effect: blurEffect)
    blur.translatesAutoresizingMaskIntoConstraints = false
    blur.contentView.translatesAutoresizingMaskIntoConstraints = false
    blur.constrain(𝗩|blur.contentView|𝗩, 𝗛|blur.contentView|𝗛)

    addSubview(blur)
    contentView = blur.contentView


  }

  public override func updateConstraints() {
    super.updateConstraints()

    let id = Identifier(self, "Internal")

    guard constraintsWithIdentifier(id).count == 0 else { return }

    let topOffset:    CGFloat = location == .Top    ? arrowHeight : 0
    let bottomOffset: CGFloat = location == .Bottom ? arrowHeight : 0

    guard let effect = contentView?.superview as? UIVisualEffectView else { return }

    constrain(
      𝗛|effect|𝗛 --> id,
      [
        effect.top => top - topOffset,
        effect.bottom => bottom + bottomOffset
        ] --> id
    )
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
  public init(backdrop image: UIImage? = nil, dismissal callback: ((PopoverView) -> Void)?) {
    dismissal = callback
    super.init(frame: CGRect.zeroRect)
    backdrop = image
    initializeIVARs()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    refreshShape()
  }

  public var backdrop: UIImage?

  public override var hidden: Bool { didSet { touchBarrier?.hidden = hidden } }

  /** removeFromSuperview */
  override public func removeFromSuperview() {
    touchBarrier?.removeFromSuperview()
    super.removeFromSuperview()
  }

  /**
  Initialization with coder is unsupported

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private weak var touchBarrier: ImageButtonView?

  /** didMoveToWindow */
  public override func didMoveToWindow() {
    super.didMoveToWindow()
    guard let window = window where self.touchBarrier == nil else { return }

    let image: UIImage? = backdrop ?? (blur ? window.blurredSnapshot() : nil)
    let touchBarrier = ImageButtonView(image: image, highlightedImage: nil) {
      [weak self] (imageView: ImageButtonView) -> Void in

      self?.dismissal?(self!)
    }

    touchBarrier.frame = window.bounds
    touchBarrier.alpha = 0.25
    touchBarrier.hidden = hidden
    window.insertSubview(touchBarrier, belowSubview: self)
    self.touchBarrier = touchBarrier
  }
}
