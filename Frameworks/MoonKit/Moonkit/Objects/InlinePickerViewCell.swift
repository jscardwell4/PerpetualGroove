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
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initializeIVARs() }

  /**
  applyLayoutAttributes:

  - parameter layoutAttributes: UICollectionViewLayoutAttributes
  */
  override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
    super.applyLayoutAttributes(layoutAttributes)

    guard let attributes = layoutAttributes as? InlinePickerViewLayout.Attributes else { return }
    layer.zPosition = attributes.zPosition ?? 0.0
    selected = attributes.containsMarker
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
    super.updateConstraints()
    let id = Identifier(self, "Internal")
    guard constraintsWithIdentifier(id).count == 0 else { return }
    constrain([𝗛|contentView|𝗛, 𝗩|contentView|𝗩] --> id)
  }
}

