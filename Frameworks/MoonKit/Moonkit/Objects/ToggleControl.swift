//
//  ToggleControl.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class ToggleControl: UIControl {


  // MARK: - Toggling

  @IBInspectable public var toggle: Bool = false
  

  // MARK: - Colors

  @IBInspectable public var disabledTintColor: UIColor?

  @IBInspectable public var highlightedTintColor: UIColor?

  // MARK: - State

  public override var selected: Bool { didSet { guard selected != oldValue else { return }; refresh() } }
  public override var enabled:  Bool { didSet { guard enabled != oldValue  else { return }; refresh() } }

  /// Tracks input to `highlighted` setter to prevent multiple calls with the same value from interfering with `toggle`
  private var previousHighlightedInput = false

  /// Overridden to implement optional toggling
  public override var highlighted: Bool {
    get { return super.highlighted }
    set {
      guard newValue != previousHighlightedInput else { return }
      switch toggle {
        case true:  super.highlighted ^= newValue
        case false: super.highlighted = newValue
      }
      previousHighlightedInput = newValue
      refresh()
    }
  }

  /**
  tintColorForState:

  - parameter state: UIControlState

  - returns: UIColor
  */
  private func tintColorForState(state: UIControlState) -> UIColor {
    let color: UIColor
    if state ∋ .Disabled && disabledTintColor != nil { color = disabledTintColor! }
    else if !state.isDisjointWith([.Highlighted, .Selected]) && highlightedTintColor != nil { color = highlightedTintColor! }
    else { color = tintColor }
    return color
  }

  private var _currentTintColor: UIColor?
  public var currentTintColor: UIColor! { return _currentTintColor ?? tintColor }

  /** refresh */
  public func refresh() { _currentTintColor = tintColorForState(state) }

  public override init(frame: CGRect) { super.init(frame: frame) }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeBool(toggle, forKey: "toggle")
    aCoder.encodeObject(highlightedTintColor, forKey:"highlightedTintColor")
    aCoder.encodeObject(disabledTintColor, forKey:"disabledTintColor")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    toggle = aDecoder.decodeBoolForKey("toggle")
    highlightedTintColor = aDecoder.decodeObjectForKey("highlightedTintColor") as? UIColor
    disabledTintColor = aDecoder.decodeObjectForKey("disabledTintColor") as? UIColor
  }
  
}