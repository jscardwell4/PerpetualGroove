//
//  ToggleImageBarButtonItem.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/31/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import UIKit

public class ToggleImageBarButtonItem: ToggleBarButtonItem {

  private weak var imageView: UIImageView!

  public override var isToggled: Bool { didSet { imageView?.highlighted = isToggled } }

  /** override `image` property to utilize the item's custom view */
  public override var image: UIImage? { get { return imageView?.image } set { imageView?.image = newValue } }

  /** computed property for accessing the custom view's highlighted image property */
  public var highlightedImage: UIImage? {
    get { return imageView?.highlightedImage }
    set { imageView?.highlightedImage = newValue }
  }

  public var disabledTintColor = UIColor.lightGrayColor()

  override public var enabled: Bool { didSet { imageView?.tintColor = enabled ? nil : disabledTintColor } }


  /**
  initWithImage:toggledImage:action:

  - parameter image: UIImage
  - parameter toggledImage: UIImage
  - parameter action: (ToggleBarButtonItem) -> Void
  */
  public init(image: UIImage, toggledImage: UIImage, action: (ToggleBarButtonItem) -> Void) {

    // create a view to hold the image view for padding purposes
    let container = UIView(frame: CGRect(origin: CGPoint.zeroPoint, size: CGSize(width: 44.0, height: 44.0)))

    // create the image view
    let imageView = UIImageView(image: image, highlightedImage: toggledImage)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.userInteractionEnabled = true
    imageView.contentMode = .ScaleAspectFit

    // add the image view to the containing view
    container.addSubview(imageView)

    // add constraints
    container.constrain(imageView.centerX => container.centerX, imageView.centerY => container.centerY,
                        imageView.top ≥ container.top + 8, imageView.bottom ≤ container.bottom - 8)

    // call super's initializer with our custom view
    super.init(customView: container)

    // add a gesture for triggering our action
    imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "toggle:"))

    // store the image view and the action parameter
    self.imageView = imageView
    toggleAction = action

  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

}
