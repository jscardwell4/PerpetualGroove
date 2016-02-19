//
//  ColorInputView.swift
//  Remote
//
//  Created by Jason Cardwell on 12/07/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit

public protocol ColorInput: class {
  var redValue:   Float { get set }
  var greenValue: Float { get set }
  var blueValue:  Float { get set }
  var alphaValue: Float { get set }
}

public final class ColorInputView: UIInputView {

  /**
  initWithFrame:colorInput:

  - parameter frame: CGRect
  - parameter colorInput: ColorInput
  */
  public init(frame: CGRect, colorInput: ColorInput) {
    super.init(frame: frame, inputViewStyle: .Keyboard)

    let r = ColorSlider(autolayout: true)
    r.style = .Gradient(.Red)
    r.value = colorInput.redValue
    r.minimumTrackTintColor = UIColor.redColor()
    r.addActionBlock({ colorInput.redValue = r.value }, forControlEvents: .ValueChanged)
    addSubview(r)

    let g = ColorSlider(autolayout: true)
    g.style = .Gradient(.Green)
    g.value = colorInput.greenValue
    g.minimumTrackTintColor = UIColor.greenColor()
    g.addActionBlock({ colorInput.greenValue = g.value }, forControlEvents: .ValueChanged)
    addSubview(g)

    let b = ColorSlider(autolayout: true)
    b.style = .Gradient(.Blue)
    b.value = colorInput.blueValue
    b.minimumTrackTintColor = UIColor.blueColor()
    b.addActionBlock({ colorInput.blueValue = b.value }, forControlEvents: .ValueChanged)
    addSubview(b)

    let a = ColorSlider(autolayout: true)
    a.style = .Gradient(.Alpha)
    a.value = colorInput.alphaValue
    a.minimumTrackTintColor = UIColor.whiteColor()
    a.addActionBlock({ colorInput.alphaValue = a.value }, forControlEvents: .ValueChanged)
    addSubview(a)

    constrain(𝗛|--r--|𝗛, 𝗛|--g--|𝗛, 𝗛|--b--|𝗛, 𝗛|--a--|𝗛, 𝗩|--(≥20)--r--g--b--a--(≥20)--|𝗩)
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

}
