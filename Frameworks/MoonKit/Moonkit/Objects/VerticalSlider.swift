//
//  VerticalSlider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit

@IBDesignable public class VerticalSlider: UIControl {

  @IBInspectable private let slider = UISlider(autolayout: true)

  /** updateConstraints */
  public override func updateConstraints() {
    super.updateConstraints()
    let id = Identifier(self, "Internal")
    guard constraintsWithIdentifier(id).count == 0 else { return }
    constrain([𝗩|slider|𝗩, 𝗛|slider|𝗛] --> id)
  }

  /** setup */
  private func setup() {
    addSubview(slider)
    layer.sublayerTransform = CATransform3DMakeRotation(-π * 0.5, 0, 0, 1)
    constrain([
      slider.width => height - 10,
      slider.height => width,
      slider.centerX => centerX,
      slider.centerY => centerY
    ] --> Identifier(self, "Internal"))
  }

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

  // MARK: - UIControl pass through methods and properties


  public override var enabled: Bool { didSet { slider.enabled = enabled } }
  public override var selected: Bool { didSet { slider.selected = selected } }
  public override var highlighted: Bool { didSet { slider.highlighted = highlighted } }

  public override var contentVerticalAlignment: UIControlContentVerticalAlignment {
    didSet { slider.contentVerticalAlignment = contentVerticalAlignment }
  }

  public override var contentHorizontalAlignment: UIControlContentHorizontalAlignment {
    didSet { slider.contentHorizontalAlignment = contentHorizontalAlignment }
  }

  /**
  beginTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    return slider.beginTrackingWithTouch(touch, withEvent: event)
  }

  /**
  continueTrackingWithTouch:withEvent:

  - parameter touch: UITouch
  - parameter event: UIEvent?

  - returns: Bool
  */
  public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    return slider.continueTrackingWithTouch(touch, withEvent: event)
  }

  /**
  endTrackingWithTouch:withEvent:

  - parameter touch: UITouch?
  - parameter event: UIEvent?
  */
  public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
    slider.endTrackingWithTouch(touch, withEvent: event)
  }

  /**
  cancelTrackingWithEvent:

  - parameter event: UIEvent?
  */
  public override func cancelTrackingWithEvent(event: UIEvent?) { slider.cancelTrackingWithEvent(event) }

  /**
  addTarget:action:forControlEvents:

  - parameter target: AnyObject?
  - parameter action: Selector
  - parameter controlEvents: UIControlEvents
  */
  public override func addTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) {
    slider.addTarget(target, action: action, forControlEvents: controlEvents)
  }

  /**
  removeTarget:action:forControlEvents:

  - parameter target: AnyObject?
  - parameter action: Selector
  - parameter controlEvents: UIControlEvents
  */
  public override func removeTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) {
    slider.removeTarget(target, action: action, forControlEvents: controlEvents)
  }

  /**
  allTargets

  - returns: Set<NSObject>
  */
  public override func allTargets() -> Set<NSObject> { return slider.allTargets() }

  /**
  allControlEvents

  - returns: UIControlEvents
  */
  public override func allControlEvents() -> UIControlEvents { return slider.allControlEvents() }

  /**
  actionsForTarget:forControlEvent:

  - parameter target: AnyObject?
  - parameter controlEvent: UIControlEvents

  - returns: [String]?
  */
  public override func actionsForTarget(target: AnyObject?, forControlEvent controlEvent: UIControlEvents) -> [String]? {
    return slider.actionsForTarget(target, forControlEvent: controlEvent)
  }


  /**
  sendAction:to:forEvent:

  - parameter action: Selector
  - parameter target: AnyObject?
  - parameter event: UIEvent?
  */
  public override func sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) {
    slider.sendAction(action, to: target, forEvent: event)
  }

  /**
  sendActionsForControlEvents:

  - parameter controlEvents: UIControlEvents
  */
  public override func sendActionsForControlEvents(controlEvents: UIControlEvents) {
    slider.sendActionsForControlEvents(controlEvents)
  }

  // MARK: - UISlider pass through methods and properties

  @IBInspectable public var value: Float { get { return slider.value } set { slider.value = newValue } }

  @IBInspectable public var minimumValue: Float { get { return slider.minimumValue } set { slider.minimumValue = newValue } }

  @IBInspectable public var maximumValue: Float { get { return slider.maximumValue } set { slider.maximumValue = newValue } }

  @IBInspectable public var minimumValueImage: UIImage? {
    get { return slider.minimumValueImage } set { slider.minimumValueImage = newValue }
  }

  @IBInspectable public var maximumValueImage: UIImage? {
    get { return slider.maximumValueImage } set { slider.maximumValueImage = newValue }
  }

  @IBInspectable public var continuous: Bool { get { return slider.continuous } set { slider.continuous = newValue } }

  @IBInspectable public var minimumTrackTintColor: UIColor? {
    get { return slider.minimumTrackTintColor } set { slider.minimumTrackTintColor = newValue }
  }

  @IBInspectable public var maximumTrackTintColor: UIColor? {
    get { return slider.maximumTrackTintColor } set { slider.maximumTrackTintColor = newValue }
  }

  @IBInspectable public var thumbTintColor: UIColor? {
    get { return slider.thumbTintColor } set { slider.thumbTintColor = newValue }
  }

  /**
  setValue:animated:

  - parameter value: Float
  - parameter animated: Bool
  */
  public func setValue(value: Float, animated: Bool) { slider.setValue(value, animated: animated) }

  /**
  setThumbImage:forState:

  - parameter image: UIImage?
  - parameter state: UIControlState
  */
  public func setThumbImage(image: UIImage?, forState state: UIControlState, color: UIColor? = nil) {
    if let color = color { slider.setThumbImage(image?.imageWithColor(color), forState: state) }
    else { slider.setThumbImage(image, forState: state) }
  }

  /**
  setMinimumTrackImage:forState:

  - parameter image: UIImage?
  - parameter state: UIControlState
  */
  public func setMinimumTrackImage(image: UIImage?, forState state: UIControlState, color: UIColor? = nil) {
    if let color = color { slider.setMinimumTrackImage(image?.imageWithColor(color), forState: state) }
    else { slider.setMinimumTrackImage(image, forState: state) }
  }

  /**
  setMaximumTrackImage:forState:

  - parameter image: UIImage?
  - parameter state: UIControlState
  */
  public func setMaximumTrackImage(image: UIImage?, forState state: UIControlState, color: UIColor? = nil) {
    if let color = color {  slider.setMaximumTrackImage(image?.imageWithColor(color), forState: state) }
    else {  slider.setMaximumTrackImage(image, forState: state) }
  }

  /**
  thumbImageForState:

  - parameter state: UIControlState

  - returns: UIImage?
  */
  public func thumbImageForState(state: UIControlState) -> UIImage? { return slider.thumbImageForState(state) }

  /**
  minimumTrackImageForState:

  - parameter state: UIControlState

  - returns: UIImage?
  */
  public func minimumTrackImageForState(state: UIControlState) -> UIImage? { return slider.minimumTrackImageForState(state) }

  /**
  maximumTrackImageForState:

  - parameter state: UIControlState

  - returns: UIImage?
  */
  public func maximumTrackImageForState(state: UIControlState) -> UIImage? { return slider.maximumTrackImageForState(state) }

  public var currentThumbImage: UIImage? { return slider.currentThumbImage }

  public var currentMinimumTrackImage: UIImage? { return slider.currentMinimumTrackImage }

  public var currentMaximumTrackImage: UIImage? { return slider.currentMaximumTrackImage }

  /**
  minimumValueImageRectForBounds:

  - parameter bounds: CGRect

  - returns: CGRect
  */
  public func minimumValueImageRectForBounds(bounds: CGRect) -> CGRect { return slider.minimumValueImageRectForBounds(bounds) }

  /**
  maximumValueImageRectForBounds:

  - parameter bounds: CGRect

  - returns: CGRect
  */
  public func maximumValueImageRectForBounds(bounds: CGRect) -> CGRect { return slider.maximumValueImageRectForBounds(bounds) }

  /**
  trackRectForBounds:

  - parameter bounds: CGRect

  - returns: CGRect
  */
  public func trackRectForBounds(bounds: CGRect) -> CGRect { return slider.trackRectForBounds(bounds) }

  /**
  thumbRectForBounds:trackRect:value:

  - parameter bounds: CGRect
  - parameter rect: CGRect
  - parameter value: Float

  - returns: CGRect
  */
  public func thumbRectForBounds(bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
    return slider.thumbRectForBounds(bounds, trackRect: rect, value: value)
  }

}
