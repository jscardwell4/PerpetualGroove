//: Playground - noun: a place where people can play
import Foundation
import UIKit
import MoonKit

let slider = UISlider(frame: CGRect(x: 0, y: 0, width: 300, height: 44))
slider

public class VerticalSlider: UIControl {

  private let slider = UISlider(autolayout: true)

  /** updateConstraints */
  public override func updateConstraints() {
    super.updateConstraints()
    let id = Identifier(self, "Internal")
    guard constraintsWithIdentifier(id).count == 0 else { return }
    constrain([𝗩|slider|𝗩, 𝗛|slider|𝗛] --> id)
  }

  /** setup */
  private func setup() {
    backgroundColor = UIColor.whiteColor()
    addSubview(slider)
    layer.sublayerTransform = CATransform3DMakeRotation(-π * 0.5, 0, 0, 1)
    constrain([slider.width => height - 10, slider.height => width, slider.centerX => centerX, slider.centerY => centerY] --> Identifier(self, "Internal"))
  }

  /**
  requiresConstraintBasedLayout

  - returns: Bool
  */
    public override class func requiresConstraintBasedLayout() -> Bool { return true }

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
  public override var contentVerticalAlignment: UIControlContentVerticalAlignment { didSet { slider.contentVerticalAlignment = contentVerticalAlignment } }
  public override var contentHorizontalAlignment: UIControlContentHorizontalAlignment { didSet { slider.contentHorizontalAlignment = contentHorizontalAlignment } }

  public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool { return slider.beginTrackingWithTouch(touch, withEvent: event) }
  public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool { return slider.continueTrackingWithTouch(touch, withEvent: event) }
  public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) { slider.endTrackingWithTouch(touch, withEvent: event) }
  public override func cancelTrackingWithEvent(event: UIEvent?) { slider.cancelTrackingWithEvent(event) }

  // add target/action for particular event. you can call this multiple times and you can specify multiple target/actions for a particular event.
  // passing in nil as the target goes up the responder chain. The action may optionally include the sender and the event in that order
  // the action cannot be NULL. Note that the target is not retained.
  public override func addTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) { slider.addTarget(target, action: action, forControlEvents: controlEvents) }

  // remove the target/action for a set of events. pass in NULL for the action to remove all actions for that target
  public override func removeTarget(target: AnyObject?, action: Selector, forControlEvents controlEvents: UIControlEvents) { slider.removeTarget(target, action: action, forControlEvents: controlEvents) }

  // get info about target & actions. this makes it possible to enumerate all target/actions by checking for each event kind
  public override func allTargets() -> Set<NSObject> { return slider.allTargets() }
  public override func allControlEvents() -> UIControlEvents { return slider.allControlEvents() }
  public override func actionsForTarget(target: AnyObject?, forControlEvent controlEvent: UIControlEvents) -> [String]? { return slider.actionsForTarget(target, forControlEvent: controlEvent) }

  // send the action. the first method is called for the event and is a point at which you can observe or override behavior. it is called repeately by the second.
  public override func sendAction(action: Selector, to target: AnyObject?, forEvent event: UIEvent?) { slider.sendAction(action, to: target, forEvent: event) }
  public override func sendActionsForControlEvents(controlEvents: UIControlEvents) { slider.sendActionsForControlEvents(controlEvents) }

  // MARK: - UISlider pass through methods and properties

  public var value: Float { get { return slider.value } set { slider.value = newValue } }
  public var minimumValue: Float { get { return slider.minimumValue } set { slider.minimumValue = newValue } }
  public var maximumValue: Float { get { return slider.maximumValue } set { slider.maximumValue = newValue } }

  public var minimumValueImage: UIImage? { get { return slider.minimumValueImage } set { slider.minimumValueImage = newValue } }
  public var maximumValueImage: UIImage? { get { return slider.maximumValueImage } set { slider.maximumValueImage = newValue } }

  public var continuous: Bool { get { return slider.continuous } set { slider.continuous = newValue } }

//  @available(iOS 5.0, *)
  public var minimumTrackTintColor: UIColor? { get { return slider.minimumTrackTintColor } set { slider.minimumTrackTintColor = newValue } }
//  @available(iOS 5.0, *)
  public var maximumTrackTintColor: UIColor? { get { return slider.maximumTrackTintColor } set { slider.maximumTrackTintColor = newValue } }
//  @available(iOS 5.0, *)
  public var thumbTintColor: UIColor? { get { return slider.thumbTintColor } set { slider.thumbTintColor = newValue } }

  public func setValue(value: Float, animated: Bool) { slider.setValue(value, animated: animated) }

  // set the images for the slider. there are 3, the thumb which is centered by default and the track. You can specify different left and right track
  // e.g blue on the left as you increase and white to the right of the thumb. The track images should be 3 part resizable (via UIImage's resizableImage methods) along the direction that is longer

  public func setThumbImage(image: UIImage?, forState state: UIControlState) { slider.setThumbImage(image, forState: state) }
  public func setMinimumTrackImage(image: UIImage?, forState state: UIControlState) { slider.setMinimumTrackImage(image, forState: state) }
  public func setMaximumTrackImage(image: UIImage?, forState state: UIControlState) { slider.setMaximumTrackImage(image, forState: state) }

  public func thumbImageForState(state: UIControlState) -> UIImage? { return slider.thumbImageForState(state) }
  public func minimumTrackImageForState(state: UIControlState) -> UIImage? { return slider.minimumTrackImageForState(state) }
  public func maximumTrackImageForState(state: UIControlState) -> UIImage? { return slider.maximumTrackImageForState(state) }

  public var currentThumbImage: UIImage? { return slider.currentThumbImage }
  public var currentMinimumTrackImage: UIImage? { return slider.currentMinimumTrackImage }
  public var currentMaximumTrackImage: UIImage? { return slider.currentMaximumTrackImage }

  // lets a subclass lay out the track and thumb as needed
  public func minimumValueImageRectForBounds(bounds: CGRect) -> CGRect { return slider.minimumValueImageRectForBounds(bounds) }
  public func maximumValueImageRectForBounds(bounds: CGRect) -> CGRect { return slider.maximumValueImageRectForBounds(bounds) }
  public func trackRectForBounds(bounds: CGRect) -> CGRect { return slider.trackRectForBounds(bounds) }
  public func thumbRectForBounds(bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect { return slider.thumbRectForBounds(bounds, trackRect: rect, value: value) }
  
}

let verticalSlider = VerticalSlider(frame: CGRect(x: 0, y: 0, width: 44, height: 300))
verticalSlider.backgroundColor = UIColor.whiteColor()
verticalSlider.setNeedsLayout()
verticalSlider.layoutIfNeeded()
verticalSlider
