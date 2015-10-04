//
//  TemplateImageView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

@IBDesignable public class TemplateImageView: UIImageView {

  override public var image: UIImage? {
    get { return super.image }
    set { super.image = newValue?.imageWithRenderingMode(.AlwaysTemplate) }
  }

  override public var highlightedImage: UIImage? {
    get { return super.highlightedImage }
    set {
      super.highlightedImage = newValue?.imageWithRenderingMode(.AlwaysTemplate).imageWithColor(highlightedTintColor ?? tintColor)
    }
  }

  @IBInspectable public var highlightedTintColor: UIColor? {
    didSet {
      highlightedImage = highlightedImage?.imageWithColor(highlightedTintColor ?? tintColor)
    }
  }
}