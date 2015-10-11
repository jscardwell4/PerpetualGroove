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
//  private var trackingTouch: UITouch? { didSet { highlighted = trackingTouch != nil } }

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
    if state ∋ .Disabled, let color = disabledTintColor {
      imageView.tintColor = color
      imageView.highlighted = false
    } else if !state.isDisjointWith([.Highlighted, .Selected]) {
      imageView.highlighted = true
      if let color = highlightedTintColor {
        imageView.tintColor = color
      }
    } else {
      imageView.tintColor = nil
      imageView.highlighted = false
    }
  }

  /// Tracks input to `highlighted` setter to prevent multiple calls with the same value from interfering with `toggle`
  private var previousHighlightedInput = false

  /// Overridden to implement optional toggling
  public override var highlighted: Bool {
    get { return super.highlighted }
    set {
      guard newValue != previousHighlightedInput else { return }
      switch toggle {
        case true:  super.highlighted ^= newValue
        case false: super.highlighted = newValue
      }
      previousHighlightedInput = newValue
      updateForState()
    }
  }

  public override var selected: Bool { didSet { logDebug(); updateForState() } }
  public override var enabled:  Bool { didSet { logDebug(); updateForState() } }

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

}
