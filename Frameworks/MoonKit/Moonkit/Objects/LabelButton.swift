//
//  LabelButton.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/23/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

@IBDesignable public class LabelButton: UIControl {

  private var touch: UITouch? { didSet { highlighted = touch != nil } }

  @IBInspectable public var toggle: Bool = false

  public override var highlighted: Bool { didSet { label?.highlighted = highlighted || selected } }

  public override var selected: Bool { didSet { label?.highlighted = highlighted || selected } }

  private weak var label: Label!

  public typealias Action = (LabelButton) -> Void

  /** setup */
  private func setup() {
    let label = Label(frame: self.bounds)
    label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    addSubview(label)
    self.label = label
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize { return label.intrinsicContentSize() }

  /**
  viewForBaselineLayout

  - returns: UIView
  */
  public override func viewForBaselineLayout() -> UIView {
    return label.viewForBaselineLayout()
  }

  @available(iOS 9.0, *)
  override public var viewForFirstBaselineLayout: UIView { return label.viewForFirstBaselineLayout }

  @available(iOS 9.0, *)
  override public var viewForLastBaselineLayout: UIView { return label.viewForLastBaselineLayout }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  public var actions: [Action] = []

  /**
  initWithAction:

  - parameter action: Action
  - parameter autoalyout: Bool = true
  */
  public convenience init(action: Action, autolayout: Bool = true) {
    self.init(frame: CGRect.zero)
    actions.append(action)
    translatesAutoresizingMaskIntoConstraints = !autolayout
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard touch == nil else { return }
    touch = touches.first
  }

  /**
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = touch where touches ∋ touch && !pointInside(touch.locationInView(self), withEvent: event) else { return }
    self.touch = nil
  }

  public override func sendActionsForControlEvents(controlEvents: UIControlEvents) {
    super.sendActionsForControlEvents(controlEvents)
    if controlEvents ∋ .TouchUpInside { actions.forEach({ $0(self) }) }
  }

  /**
  touchesEnded:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = touch where touches ∋ touch  else { return }
    if pointInside(touch.locationInView(self), withEvent: event) {
      if toggle { selected = !selected }
      sendActionsForControlEvents(.TouchUpInside)
    }
    self.touch = nil
  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>?
  - parameter event: UIEvent?
  */
  public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    guard let touches = touches, touch = touch where touches ∋ touch else { return }
    self.touch = nil
  }

  // MARK: - Wrapping Label

  @IBInspectable public var tintColorAlpha: CGFloat {
    get { return label?.tintColorAlpha ?? 0 }
    set { label?.tintColorAlpha = newValue }
  }

  @IBInspectable public var highlightedTintColorAlpha: CGFloat {
    get { return label?.highlightedTintColorAlpha ?? 0 }
    set { label?.highlightedTintColorAlpha = newValue }
  }

  @IBInspectable public var text: String? {
    get { return label?.text } 
    set { label?.text = newValue; invalidateIntrinsicContentSize() }
  }

  public var font: UIFont! { 
    get { return label?.font ?? .systemFontOfSize(17) } 
    set { label?.font = newValue; invalidateIntrinsicContentSize() } 
  }

  @objc @IBInspectable private var fontName: String {
    get { return font.fontName }
    set { if let font = UIFont(name: newValue, size: font.pointSize) { self.font = font } }
  }

  @objc @IBInspectable private var fontSize: CGFloat {
    get { return font.pointSize }
    set { font = font.fontWithSize(newValue) }
  }

  @IBInspectable public var textColor: UIColor! {
    get { return label?.textColor ?? .blackColor() } 
    set { label?.textColor = newValue } 
  }

  @IBInspectable public var shadowColor: UIColor? {
    get { return label?.shadowColor } 
    set { label?.shadowColor = newValue } 
  }

  @IBInspectable public var shadowOffset: CGSize {
    get { return label?.shadowOffset ?? .zero } 
    set { label?.shadowOffset = newValue } 
  }

  public var textAlignment: NSTextAlignment {
    get { return label?.textAlignment ?? .Left } 
    set { label?.textAlignment = newValue } 
  }

  @objc @IBInspectable private var textAlignmentString: String {
    get {
      switch textAlignment {
        case .Left: return "Left"
        case .Center: return "Center"
        case .Right: return "Right"
        case .Justified: return "Justified"
        case .Natural: return "Natural"
      }
    }
    set {
      switch newValue {
        case "Left": textAlignment = .Left
        case "Center": textAlignment = .Center
        case "Right": textAlignment = .Right
        case "Justified": textAlignment = .Justified
        case "Natural": textAlignment = .Natural
        default: break
      }
    }
  }

  public var lineBreakMode: NSLineBreakMode {
    get { return label?.lineBreakMode ?? .ByTruncatingTail } 
    set { label?.lineBreakMode = newValue; invalidateIntrinsicContentSize() }
  }

  @objc @IBInspectable private var lineBreakModeString: String {
    get {
      switch lineBreakMode {
        case .ByWordWrapping: return "ByWordWrapping"
        case .ByCharWrapping: return "ByCharWrapping"
        case .ByClipping: return "ByClipping"
        case .ByTruncatingHead: return "ByTruncatingHead"
        case .ByTruncatingTail: return "ByTruncatingTail"
        case .ByTruncatingMiddle: return "ByTruncatingMiddle"
      }
    }
    set {
      switch newValue {
        case "ByWordWrapping": lineBreakMode = .ByWordWrapping
        case "ByCharWrapping": lineBreakMode = .ByCharWrapping
        case "ByClipping": lineBreakMode = .ByClipping
        case "ByTruncatingHead": lineBreakMode = .ByTruncatingHead
        case "ByTruncatingTail": lineBreakMode = .ByTruncatingTail
        case "ByTruncatingMiddle": lineBreakMode = .ByTruncatingMiddle
        default: break
      }
    }
  }
  
  public var attributedText: NSAttributedString? { 
    get { return label?.attributedText } 
    set { label?.attributedText = newValue; invalidateIntrinsicContentSize() }
  }

  @IBInspectable public var highlightedTextColor: UIColor? { 
    get { return label?.highlightedTextColor } 
    set { label?.highlightedTextColor = newValue } 
  }

  public override var enabled: Bool { didSet { label?.enabled = enabled; label?.setNeedsDisplay(); setNeedsDisplay() } }

  @IBInspectable public var numberOfLines: Int { 
    get { return label?.numberOfLines ?? 1 } 
    set { label?.numberOfLines = newValue; invalidateIntrinsicContentSize() }
  }

  @IBInspectable public var adjustsFontSizeToFitWidth: Bool { 
    get { return label?.adjustsFontSizeToFitWidth ?? false } 
    set { label?.adjustsFontSizeToFitWidth = newValue; invalidateIntrinsicContentSize() }
  }

  public var baselineAdjustment: UIBaselineAdjustment {
    get { return label?.baselineAdjustment ?? .AlignBaselines } 
    set { label?.baselineAdjustment = newValue } 
  }

  @objc @IBInspectable private var baselineAdjustmentString: String {
    get {
      switch baselineAdjustment {
        case .AlignBaselines: return "AlignBaselines"
        case .AlignCenters: return "AlignCenters"
        case .None: return "None"
      }
    }
    set {
      switch newValue {
        case "AlignBaselines": baselineAdjustment = .AlignBaselines
        case "AiignCenters": baselineAdjustment = .AlignCenters
        case "None": baselineAdjustment = .None
        default: break
      }
    }
  }

  @IBInspectable public var minimumScaleFactor: CGFloat {
    get { return label?.minimumScaleFactor ?? 0 } 
    set { label?.minimumScaleFactor = newValue; invalidateIntrinsicContentSize() }
  }

  @available(iOS 9.0, *)
  @IBInspectable public var allowsDefaultTighteningForTruncation: Bool { 
    get { return label?.allowsDefaultTighteningForTruncation ?? false } 
    set { label?.allowsDefaultTighteningForTruncation = newValue; invalidateIntrinsicContentSize() }
  }

  /**
  textRectForBounds:limitedToNumberOfLines:

  - parameter bounds: CGRect
  - parameter numberOfLines: Int

  - returns: CGRect
  */
  public func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect { 
    return label?.textRectForBounds(bounds, limitedToNumberOfLines: numberOfLines) ?? bounds 
  }

  @IBInspectable public var preferredMaxLayoutWidth: CGFloat { 
    get { return label?.preferredMaxLayoutWidth ?? 0 } 
    set { label?.preferredMaxLayoutWidth = newValue; invalidateIntrinsicContentSize() }
  }

}
