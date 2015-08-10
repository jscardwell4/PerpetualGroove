//
//  Slider.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/6/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public class Slider: UISlider {

  // MARK: - Enumeration to specify the style of the slider's thumb button
  public enum ThumbStyle: Equatable {

    public enum ColorType { case Red, Green, Blue, Alpha }

    case Default
    case Custom ((Slider) -> UIImage)
    case OneTone (ColorType)
    case TwoTone (ColorType)
    case Gradient (ColorType)

  }

  public var thumbOffset = UIOffset.zeroOffset

  /**
  thumbRectForBounds:trackRect:value:

  - parameter bounds: CGRect
  - parameter rect: CGRect
  - parameter value: Float

  - returns: CGRect
  */
  public override func thumbRectForBounds(bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
    return super.thumbRectForBounds(bounds, trackRect: rect, value: value)
                .rectByOffsetting(dx: thumbOffset.horizontal, dy: thumbOffset.vertical)
  }

  public var style: ThumbStyle = .Default {
    didSet {
      if case .Default = style {
        removeTarget(self, action: nil, forControlEvents: .ValueChanged)
      } else if actionsForTarget(self, forControlEvent: .ValueChanged) == nil {
        updateThumbImage()
        addTarget(self, action: "updateThumbImage", forControlEvents: .ValueChanged)
      }
    }
  }

  override public var value: Float { didSet { if style != ThumbStyle.Default { updateThumbImage() } } }

  /** updateThumbImage */
  func updateThumbImage() {

    let value = CGFloat(self.value / minimumValue.distanceTo(maximumValue))
    var image: UIImage?

    switch style {

      case .Custom(let generateThumbImage):
        image = generateThumbImage(self)

      case .OneTone(let colorType):
        switch colorType {
          case .Red:
            image = DrawingKit.imageOfRedCircle(opacity: value)
          case .Green:
            image = DrawingKit.imageOfGreenCircle(opacity: value)
          case .Blue:
            image = DrawingKit.imageOfBlueCircle(opacity: value)
          case .Alpha:
            image = DrawingKit.imageOfAlphaCircle(opacity: value)
        }

      case .TwoTone(let colorType):
        switch colorType {
          case .Red:
            image = DrawingKit.imageOfRedValueCircle(value: value)
          case .Green:
            image = DrawingKit.imageOfGreenValueCircle(value: value)
          case .Blue:
            image = DrawingKit.imageOfBlueValueCircle(value: value)
          case .Alpha:
            image = DrawingKit.imageOfAlphaValueCircle(value: value)
        }

      case .Gradient(let colorType):
        switch colorType {
          case .Red:
            image = DrawingKit.imageOfRedGradientCircle(opacity: value)
          case .Green:
            image = DrawingKit.imageOfGreenGradientCircle(opacity: value)
          case .Blue:
            image = DrawingKit.imageOfBlueGradientCircle(opacity: value)
          case .Alpha:
            image = DrawingKit.imageOfAlphaGradientCircle(opacity: value)
        }

      case .Default: image = currentThumbImage

    }
    setThumbImage(image, forState: .Normal)
  }

}

public func ==(lhs: Slider.ThumbStyle, rhs: Slider.ThumbStyle) -> Bool {
  switch (lhs, rhs) {
    case (.Default, .Default), (.OneTone, .OneTone), (.TwoTone, .TwoTone), (.Gradient, .Gradient), (.Custom, .Custom): return true
    default: return false
  }
}
