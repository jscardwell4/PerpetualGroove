//
//  ImageButtonView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

// TODO: Just make this a control
@IBDesignable public class ImageButtonView: UIControl {

  // MARK: - Private properties
  private let imageView = UIImageView(autolayout: true)
  private var trackingTouch: UITouch? { didSet { highlighted = trackingTouch != nil } }

  // MARK: - Toggling

  @IBInspectable public var toggle: Bool = false

  // MARK: - Images

  @IBInspectable public var image: UIImage? {
    get { return imageView.image }
    set { imageView.image = newValue?.imageWithRenderingMode(.AlwaysTemplate) }
  }

  @IBInspectable public var highlightedImage: UIImage? {
    get { return imageView.highlightedImage }
    set { imageView.highlightedImage = newValue?.imageWithRenderingMode(.AlwaysTemplate) }
  }

  // MARK: - Colors

  @IBInspectable public var disabledTintColor: UIColor?

  @IBInspectable public var highlightedTintColor: UIColor?

  // MARK: - Managing state

  private func updateForState() {
    if state ∋ .Disabled, let color = disabledTintColor { imageView.tintColor = color }
    else if !state.isDisjointWith([.Highlighted, .Selected]), let color = highlightedTintColor { imageView.tintColor = color }
    else { imageView.tintColor = nil }
  }

  @IBInspectable public override var highlighted: Bool { didSet { updateForState() } }
  @IBInspectable public override var selected: Bool    { didSet { updateForState() } }
  @IBInspectable public override var enabled: Bool     { didSet { updateForState() } }

  // MARK: - Initializing

  /** initializeIVARs */
  private func setup() { addSubview(imageView); constrain(𝗩|imageView|𝗩, 𝗛|imageView|𝗛) }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeBool(toggle, forKey: "toggle")
    aCoder.encodeObject(image, forKey: "image")
    aCoder.encodeObject(highlightedImage, forKey: "highlightedImage")
    aCoder.encodeObject(highlightedTintColor, forKey:"highlightedTintColor")
    aCoder.encodeObject(disabledTintColor, forKey:"disabledTintColor")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    toggle = aDecoder.decodeBoolForKey("toggle")
    image = aDecoder.decodeObjectForKey("image") as? UIImage
    highlightedImage = aDecoder.decodeObjectForKey("highlightedImage") as? UIImage
    highlightedTintColor = aDecoder.decodeObjectForKey("highlightedTintColor") as? UIColor
    disabledTintColor = aDecoder.decodeObjectForKey("disabledTintColor") as? UIColor
    setup()
  }

  // MARK: - Touch handling

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if trackingTouch == nil { trackingTouch = touches.first }
  }

  /**
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let trackingTouch = trackingTouch
      where touches.contains(trackingTouch) && !pointInside(trackingTouch.locationInView(self), withEvent: event)
    {
      self.trackingTouch = nil
    }
  }

  /**
  touchesEnded:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent?
  */
  public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let trackingTouch = trackingTouch where touches.contains(trackingTouch) {
      if pointInside(trackingTouch.locationInView(self), withEvent: event) {
        if toggle { selected = !selected }
        sendActionsForControlEvents(.TouchUpInside)
      }
      self.trackingTouch = nil
    }
  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>?
  - parameter event: UIEvent?
  */
  public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let touches = touches, trackingTouch = trackingTouch where touches.contains(trackingTouch) {
      self.trackingTouch = nil
    }
  }
}
