//
//  LabeledSlider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class LabeledSlider: UIControl {

  public override init(frame: CGRect) { super.init(frame: frame); initializeIVARs() }
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initializeIVARs() }

  func initializeIVARs() {
    addSubview(label); addSubview(slider)

    label.textColor = textColor
    label.font = font
    label.highlightedTextColor = highlightedTextColor
    
    slider.addTarget(self, action: "updateLabel", forControlEvents: .ValueChanged)
  }

  public override class func requiresConstraintBasedLayout() -> Bool { return true }

  public override func updateConstraints() {
    removeAllConstraints()
    super.updateConstraints()
    constrain(𝗛|label -- 8 -- slider|𝗛, 𝗩|label|𝗩, 𝗩|slider|𝗩)
  }

  public override func intrinsicContentSize() -> CGSize {
    let lsize = label.intrinsicContentSize()
    let ssize = slider.intrinsicContentSize()
    return CGSize(width: lsize.width + 8 + ssize.width, height: max(lsize.height, ssize.height))
  }


  // MARK: - Label

  private let label = UILabel(autolayout: true)

  func updateLabel() { label.text = String(Double(slider.value), precision: precision) }

  /** The number of characters from the fractional part of `slider.value` to display, defaults to `0` */
  public var precision = 0 { didSet { updateLabel() } }

  // MARK: Properties bounced to/from `UILabel` subview

  public var font: UIFont = .preferredFontForTextStyle(UIFontTextStyleHeadline)  {
    didSet { label.font = font }
  }
  public var highlightedTextColor: UIColor? {
   didSet { label.highlightedTextColor = highlightedTextColor }
  }
  public var textColor: UIColor = .blackColor() { didSet { label.textColor = textColor } }
  public var shadowColor: UIColor? { didSet { label.shadowColor = shadowColor } }
  public var shadowOffset: CGSize = .zeroSize { didSet { label.shadowOffset = shadowOffset } }
  public var adjustsFontSizeToFitWidth: Bool {
    get { return label.adjustsFontSizeToFitWidth }
    set { label.adjustsFontSizeToFitWidth = newValue }
  }
  public var baselineAdjustment: UIBaselineAdjustment {
    get { return label.baselineAdjustment }
    set { label.baselineAdjustment = newValue }
  }
  public var minimumScaleFactor: CGFloat { get { return label.minimumScaleFactor } set { label.minimumScaleFactor = newValue } }
  public var preferredMaxLayoutWidth: CGFloat {
    get { return label.preferredMaxLayoutWidth }
    set { label.preferredMaxLayoutWidth = newValue }
  }

  // MARK: - Slider

  private let slider = Slider(autolayout: true)

  // MARK: Properties bounced to/from the `Slider` subview

  public var thumbOffset: UIOffset { get { return slider.thumbOffset } set { slider.thumbOffset = newValue } }
  public var style: Slider.ThumbStyle { get { return slider.style } set { slider.style = newValue } }

  public var continuous: Bool { get { return slider.continuous } set { slider.continuous = newValue } }

  public var value: Float { get { return slider.value } set { slider.value = newValue; updateLabel() } }
  public var minimumValue: Float { get { return slider.minimumValue } set { slider.minimumValue = newValue } }
  public var maximumValue: Float { get { return slider.maximumValue } set { slider.maximumValue = newValue } }

  public override var enabled: Bool { get { return slider.enabled } set { slider.enabled = newValue } }
  public override var selected: Bool { get { return slider.selected } set { slider.selected = newValue } }
  public override var highlighted: Bool { get { return slider.highlighted } set { slider.highlighted = newValue } }

  public override var state: UIControlState { return slider.state }

  public override var contentVerticalAlignment: UIControlContentVerticalAlignment {
    get { return slider.contentVerticalAlignment }
    set { slider.contentVerticalAlignment = newValue }
  }

  public override var contentHorizontalAlignment: UIControlContentHorizontalAlignment {
    get { return slider.contentHorizontalAlignment }
    set { slider.contentHorizontalAlignment = newValue }
  }

  // MARK: Methods bounced to the `Slider` subview

  public func setMinimumTrackImage(image: UIImage?, forState state: UIControlState) {
    slider.setMinimumTrackImage(image, forState: state)
  }

  public func minimumTrackImageForState(state: UIControlState) -> UIImage? { return slider.minimumTrackImageForState(state) }

  public var currentMinimumTrackImage: UIImage? { return slider.currentMinimumTrackImage }

  public func setMaximumTrackImage(image: UIImage?, forState state: UIControlState)
  {
    slider.setMaximumTrackImage(image, forState: state)
  }

  public func maximumTrackImageForState(state: UIControlState) -> UIImage? {
    return slider.maximumTrackImageForState(state)
  }

  public var currentMaximumTrackImage: UIImage? { return slider.currentMaximumTrackImage }

  public func setThumbImage(image: UIImage?, forState state: UIControlState) {
    slider.setThumbImage(image, forState: state)
  }

  public func thumbImageForState(state: UIControlState) -> UIImage? { return slider.thumbImageForState(state) }

  public var currentThumbImage: UIImage? { return slider.currentThumbImage }

  public var minimumTrackTintColor: UIColor? {
    get { return slider.minimumTrackTintColor }
    set { slider.minimumTrackTintColor = newValue }
  }

  public var maximumTrackTintColor: UIColor? {
    get { return slider.maximumTrackTintColor }
    set { slider.maximumTrackTintColor = newValue }
  }

  public var thumbTintColor: UIColor? {
    get { return slider.thumbTintColor }
    set { slider.thumbTintColor = newValue }
  }

  public var minimumValueImage: UIImage? {
    get { return slider.minimumValueImage }
    set { slider.minimumValueImage = newValue }
  }

  public var maximumValueImage: UIImage? {
    get { return slider.maximumValueImage }
    set { slider.maximumValueImage = newValue }
  }

  // MARK: UIControl overrides

  public override var tracking: Bool { return slider.tracking }
  public override var touchInside: Bool { return slider.touchInside }

  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    return slider.beginTrackingWithTouch(touch, withEvent: event)
  }
  public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
    return slider.continueTrackingWithTouch(touch, withEvent: event)
  }
  public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
    slider.endTrackingWithTouch(touch, withEvent: event)
  }
  public override func cancelTrackingWithEvent(event: UIEvent?) {
    slider.cancelTrackingWithEvent(event)
  }

  public override func addTarget(target: AnyObject?,
                          action: Selector,
                forControlEvents controlEvents: UIControlEvents)
  {
    slider.addTarget(target, action: action, forControlEvents: controlEvents)
  }

  public override func removeTarget(target: AnyObject?,
                             action: Selector,
                   forControlEvents controlEvents: UIControlEvents)
  {
    slider.removeTarget(target, action: action, forControlEvents: controlEvents)
  }

  public override func allTargets() -> Set<NSObject> { return slider.allTargets() }
  public override func allControlEvents() -> UIControlEvents { return slider.allControlEvents() }

  public override func actionsForTarget(target: AnyObject?,
                        forControlEvent controlEvent: UIControlEvents) -> [String]?
  {
    return slider.actionsForTarget(target, forControlEvent: controlEvent)
  }

  public override func sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) {
    slider.sendAction(action, to: target, forEvent: event)
  }

  public override func sendActionsForControlEvents(controlEvents: UIControlEvents) {
    slider.sendActionsForControlEvents(controlEvents)
  }

}
