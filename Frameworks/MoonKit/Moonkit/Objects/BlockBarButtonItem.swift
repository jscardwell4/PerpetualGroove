//
//  BlockBarButtonItem.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/2/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import UIKit

public class BlockBarButtonItem: UIBarButtonItem {

  public var buttonAction: ((Void) -> Void)?

  /** init */
  public override init() {
    super.init()
    super.target = self
    super.action = "handler"
  }

//  public convenience init(image: UIImage, toggledImage: UIImage, action: ((Void) -> Void)?) {
//    self.init(image: image, style: .Plain, target: nil, action: nil)
//    buttonAction = action
//  }

  public convenience init(image: UIImage?, style: UIBarButtonItemStyle, action: ((Void) -> Void)?) {
    self.init(image: image, style: style, target: nil, action: nil)
    buttonAction = action
  }

  public convenience init(image: UIImage?, landscapeImagePhone: UIImage?, style: UIBarButtonItemStyle, action: ((Void) -> Void)?) {
    self.init(image: image, landscapeImagePhone: landscapeImagePhone, style: style, target: nil, action: nil)
    buttonAction = action
  }

  public convenience init(title: String?, style: UIBarButtonItemStyle, action: ((Void) -> Void)?) {
    self.init(title: title, style: style, target: nil, action: nil)
    buttonAction = action
  }

  public convenience init(barButtonSystemItem systemItem: UIBarButtonSystemItem, action: ((Void) -> Void)?) {
    self.init(barButtonSystemItem: systemItem, target: nil, action: nil)
    buttonAction = action
  }

  public convenience init(customView: UIView, action: ((Void) -> Void)?) {
    self.init(customView: customView)
    buttonAction = action
  }


  public override var action: Selector { get { return super.action } set {} }

  public override var target: AnyObject? { get { return super.target } set {} }

  /** toggle */
  public func handler() { buttonAction?() }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) { super.encodeWithCoder(aCoder) }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }



}
