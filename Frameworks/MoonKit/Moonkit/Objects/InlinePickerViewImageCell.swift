//
//  InlinePickerViewImageCell.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

final class InlinePickerViewImageCell: InlinePickerViewCell {

  private let imageView = UIImageView(autolayout: true)

  var image: UIImage? { didSet { imageView.image = image } }
  var imageColor: UIColor? { didSet { imageView.tintColor = imageColor } }
  var imageSelectedColor: UIColor? { didSet { guard selected else { return }; imageView.tintColor = imageSelectedColor } }

  /** initializeIVARs */
  override func initializeIVARs() {
    super.initializeIVARs()

    imageView.contentMode = .ScaleAspectFit
    contentView.addSubview(imageView)
  }

  override var selected: Bool { didSet { imageView.tintColor = selected ? imageSelectedColor : imageColor } }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame) }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    image = aDecoder.decodeObjectForKey("InlinePickerViewCellImage") as? UIImage
  }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    if let keyedCoder = aCoder as? NSKeyedArchiver {
      keyedCoder.encodeObject(image, forKey: "InlinePickerViewCellImage")
    }
  }

  /** updateConstraints */
  override func updateConstraints() {
    super.updateConstraints()
    constrain(𝗛|imageView|𝗛, 𝗩|imageView|𝗩)
  }

}