//

//  ImageButtonView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

// TODO: Just make this a control
@IBDesignable public class ImageButtonView: ToggleControl {

  // MARK: - Private properties
  private let imageView = UIImageView(autolayout: true)


  // MARK: - Images

  @IBInspectable public var image: UIImage? {
    get { return imageView.image }
    set { imageView.image = newValue?.imageWithRenderingMode(.AlwaysTemplate) }
  }

  @IBInspectable public var highlightedImage: UIImage? {
    get { return imageView.highlightedImage }
    set { imageView.highlightedImage = newValue?.imageWithRenderingMode(.AlwaysTemplate) }
  }

  public override func refresh() {
    super.refresh()
    imageView.tintColor = currentTintColor
    imageView.highlighted = highlighted
  }

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
    aCoder.encodeObject(image, forKey: "image")
    aCoder.encodeObject(highlightedImage, forKey: "highlightedImage")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    image = aDecoder.decodeObjectForKey("image") as? UIImage
    highlightedImage = aDecoder.decodeObjectForKey("highlightedImage") as? UIImage
    setup()
  }

}
