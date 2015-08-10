//
//  TwoToneSlider.swift
//  Remote
//
//  Created by Jason Cardwell on 12/08/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit

public class TwoToneSlider: UISlider {

  public enum GeneratedColorType { case Custom, Red, Green, Blue, Alpha }

  public var generatedColorType: GeneratedColorType = .Custom { didSet { updateThumbImage() } }

  public var lowerColor: (TwoToneSlider) -> UIColor = { _ -> UIColor in return UIColor.whiteColor() }
  public var upperColor: (TwoToneSlider) -> UIColor = { _ -> UIColor in return UIColor.whiteColor() }

  /** updateThumbImage */
  func updateThumbImage() {
    var image: UIImage
    switch generatedColorType {
      case .Custom:
        image = DrawingKit.imageOfTwoToneCircle(upperColor: upperColor(self), lowerColor: lowerColor(self))
      case .Red:
        image = DrawingKit.imageOfRedValueCircle(value: CGFloat(value))
      case .Green:
        image = DrawingKit.imageOfGreenValueCircle(value: CGFloat(value))
      case .Blue:
        image = DrawingKit.imageOfBlueValueCircle(value: CGFloat(value))
      case .Alpha:
        image = DrawingKit.imageOfAlphaValueCircle(value: CGFloat(value))
    }
    setThumbImage(image, forState: .Normal)
  }

  public override var minimumValue: Float { get { return 0.0 } set {} }
  public override var maximumValue: Float { get { return 1.0 } set {} }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) {
    super.init(frame: frame)
    addTarget(self, action: "updateThumbImage", forControlEvents: .ValueChanged)
  }

  /**
  initWithAutolayout:

  - parameter autolayout: Bool
  */
  public convenience init(autolayout: Bool = false) {
    self.init(frame: CGRect.zeroRect)
    translatesAutoresizingMaskIntoConstraints = !autolayout
  }

  /**
  initWithType:autolayout:

  - parameter type: GeneratedColorType
  - parameter autolayout: Bool = false
  */
  public convenience init(type: GeneratedColorType, autolayout: Bool = false) {
    self.init(autolayout: autolayout)
    generatedColorType = type
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

}
