//
//  InlinePickerViewCell.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

class InlinePickerViewCell: UICollectionViewCell {

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame); initializeIVARs() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initializeIVARs()
  }

  /**
  applyLayoutAttributes:

  - parameter layoutAttributes: UICollectionViewLayoutAttributes
  */
  override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
    super.applyLayoutAttributes(layoutAttributes)

    layer.zPosition = (layoutAttributes as? InlinePickerViewLayout.Attributes)?.zPosition ?? 0.0
  }


  /** initializeIVARs */
  func initializeIVARs() {
    layer.doubleSided = false
    layer.shouldRasterize = true
    layer.rasterizationScale = UIScreen.mainScreen().scale

    translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false

  }

  /**
  requiresConstraintBasedLayout

  - returns: Bool
  */
  override class func requiresConstraintBasedLayout() -> Bool { return true }

  /** updateConstraints */
  override func updateConstraints() {
    removeAllConstraints()
    super.updateConstraints()
    constrain(𝗛|contentView|𝗛, 𝗩|contentView|𝗩)
  }
}

