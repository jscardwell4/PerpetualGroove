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

  private let imageView = UIImageView(autolayout: true)

  @IBInspectable public var toggle: Bool = false
  @IBInspectable public var image: UIImage? {
    get { return imageView.image }
    set { imageView.image = newValue?.imageWithRenderingMode(.AlwaysTemplate) }
  }
  @IBInspectable public var highlightedImage: UIImage? {
    get { return imageView.highlightedImage }
    set { imageView.highlightedImage = newValue?.imageWithRenderingMode(.AlwaysTemplate) }
  }

  @IBInspectable var isToggled: Bool = false { didSet { highlighted = isToggled } }

  private var trackingTouch: UITouch? { didSet { highlighted = trackingTouch != nil || isToggled } }

  @IBInspectable public var disabledTintColor: UIColor?

  @IBInspectable public var highlightedTintColor: UIColor?

  @IBInspectable public override var highlighted: Bool {
    didSet {
      if highlighted || selected, let color = highlightedTintColor { imageView.tintColor = color }
      else { imageView.tintColor = nil }
      imageView.highlighted = highlighted || selected
    }
  }

  @IBInspectable public override var selected: Bool {
    didSet {
      if highlighted || selected, let color = highlightedTintColor { imageView.tintColor = color }
      else { imageView.tintColor = nil }
      imageView.highlighted = highlighted || selected
    }
  }

  @IBInspectable public override var enabled: Bool {
    didSet {
      if !enabled, let color = disabledTintColor { imageView.tintColor = color }
      else if highlighted || selected, let color = highlightedTintColor { imageView.tintColor = color }
      else { imageView.tintColor = nil }
    }
  }


  /** initializeIVARs */
  private func initializeIVARs() { addSubview(imageView); constrain(𝗩|imageView|𝗩, 𝗛|imageView|𝗛) }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); initializeIVARs() }

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
    initializeIVARs()
  }
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
        if toggle { isToggled = !isToggled }
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
