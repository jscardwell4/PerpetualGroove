//
//  ImageBarButtonItem.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/9/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

//@IBDesignable
public class ImageBarButtonItem: UIBarButtonItem {

  public override var image: UIImage? { didSet { imageButtonView?.image = image } }
  @IBInspectable public var highlightedImage: UIImage? {
    didSet {
      imageButtonView?.highlightedImage = highlightedImage
    }
  }

  @IBInspectable public var toggle: Bool = false { didSet { imageButtonView?.toggle = toggle } }

  private weak var imageButtonView: ImageButtonView? {
    didSet {
      imageButtonView?.tintColor = tintColor
      imageButtonView?.toggle = toggle
    }
  }

//  private func imageButtonViewWithImage(image: UIImage?, highlightedImage: UIImage?) -> ImageButtonView {
//    let result = ImageButtonView(image: image, highlightedImage: highlightedImage) {
//      [weak self] _ in
//
//      if let target = self?.target as? NSObjectProtocol, selector = self?.action {
//        switch String(selector) {
//        case ~/".+:": target.performSelector(selector, withObject: self!)
//        default: target.performSelector(selector)
//        }
//      }
//    }
//    result.contentMode = .ScaleAspectFit
//    result.translatesAutoresizingMaskIntoConstraints = false
//    return result
//  }

  public override var enabled: Bool {
    didSet {
      guard let disabledTintColor = disabledTintColor else { return }
      imageButtonView?.tintColor = enabled ? tintColor : disabledTintColor
    }
  }
  public override var tintColor: UIColor? {
    didSet { guard enabled || disabledTintColor == nil else { return }; imageButtonView?.tintColor = tintColor }
  }
  @IBInspectable public var disabledTintColor: UIColor? {
    didSet { if !enabled, let color = disabledTintColor { imageButtonView?.tintColor = color } }
  }

  @IBInspectable public var highlightedTintColor: UIColor? {
    didSet { imageButtonView?.highlightedTintColor = highlightedTintColor }
  }

  /**
  initWithImage:highlightedImage:target:action:

  - parameter image: UIImage?
  - parameter highlightedImage: UIImage?
  - parameter target: AnyObject?
  - parameter action: Selector
  */
  public init(image: UIImage?, highlightedImage: UIImage?, target :AnyObject?, action: Selector) {
    super.init()
    self.target = target
    self.action = action
    self.image = image
    self.highlightedImage = highlightedImage
//    let customView = UIView(frame: CGRect(x: 6, y: 6, width: 32, height: 32))
//    let imageButtonView = imageButtonViewWithImage(image, highlightedImage: highlightedImage)
//    imageButtonView.toggle = toggle
//    customView.addSubview(imageButtonView)
//    customView.constrain(𝗩|imageButtonView|𝗩, 𝗛|imageButtonView|𝗛)
//    self.imageButtonView = imageButtonView
//    self.customView = customView
  }

  /**
  initWithImage:style:target:action:

  - parameter image: UIImage?
  - parameter style: UIBarButtonItemStyle
  - parameter target: AnyObject?
  - parameter action: Selector
  */
  public convenience init(image: UIImage?, style: UIBarButtonItemStyle, target: AnyObject?, action: Selector) {
    self.init(image: image, highlightedImage: nil, target: target, action: action)
  }

  /**
  initWithImage:landscapeImagePhone:style:target:action:

  - parameter image: UIImage?
  - parameter landscapeImagePhone: UIImage?
  - parameter style: UIBarButtonItemStyle
  - parameter target: AnyObject?
  - parameter action: Selector
  */
  public convenience init(image: UIImage?, landscapeImagePhone: UIImage?, style: UIBarButtonItemStyle, target: AnyObject?, action: Selector) {
    self.init(image: image, highlightedImage: nil, target: target, action: action)

  }

  /**
  initWithTitle:style:target:action:

  - parameter title: String?
  - parameter style: UIBarButtonItemStyle
  - parameter target: AnyObject?
  - parameter action: Selector
  */
  public convenience init(title: String?, style: UIBarButtonItemStyle, target: AnyObject?, action: Selector) {
    self.init(image: nil, highlightedImage: nil, target: target, action: action)
  }

  /**
  init:target:action:

  - parameter systemItem: UIBarButtonSystemItem
  - parameter target: AnyObject?
  - parameter action: Selector
  */
  public convenience init(barButtonSystemItem systemItem: UIBarButtonSystemItem, target: AnyObject?, action: Selector) {
    self.init(image: nil, highlightedImage: nil, target: target, action: action)
  }

  /**
  initWithCustomView:

  - parameter customView: UIView
  */
  public convenience init(customView: UIView) {
    self.init(image: nil, highlightedImage: nil, target: nil, action: nil)
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    highlightedImage = aDecoder.decodeObjectForKey("highlightedImage") as? UIImage
    toggle = aDecoder.decodeBoolForKey("toggle")
//    let customView = UIView(frame: CGRect(x: 6, y: 6, width: 32, height: 32))
//    let imageButtonView = imageButtonViewWithImage(image, highlightedImage: highlightedImage)
//    imageButtonView.toggle = toggle
//    customView.addSubview(imageButtonView)
//    customView.constrain(𝗩|imageButtonView|𝗩, 𝗛|imageButtonView|𝗛)
//    self.imageButtonView = imageButtonView
//    self.customView = customView
  }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeObject(highlightedImage, forKey: "highlightedImage")
    aCoder.encodeBool(toggle, forKey: "toggle")
  }

}