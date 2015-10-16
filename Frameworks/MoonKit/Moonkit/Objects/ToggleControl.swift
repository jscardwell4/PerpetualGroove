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

  // TODO: Make this work again
  /// Whether changes to `highlighted` should toggle `selected`
  @IBInspectable public var toggle: Bool = false

  // MARK: - Colors

  @IBInspectable public var highlightedTintColor: UIColor? { didSet { refresh() } }
  @IBInspectable public var disabledTintColor:    UIColor? { didSet { refresh() } }
  @IBInspectable public var selectedTintColor:    UIColor? { didSet { refresh() } }

  // MARK: - State

  public override var enabled: Bool { didSet { if enabled != oldValue { refresh() } } }

  private var toggleBegan = false

  public override var highlighted: Bool {
    didSet {
      guard highlighted != oldValue else { return }
      if toggle && toggleBegan && !highlighted { selected.toggle() }
      else if toggle && !toggleBegan && highlighted { toggleBegan = true }
      refresh()
    }
  }



  /// Overridden to implement optional toggling
  public override var selected: Bool { didSet { if selected != oldValue { toggleBegan = false; refresh() } } }

  /**
  tintColorForState:

  - parameter state: UIControlState

  - returns: UIColor
  */
  private func tintColorForState(state: UIControlState) -> UIColor {
    let color: UIColor
    switch state {
      case [.Disabled] where disabledTintColor != nil:                  color = disabledTintColor!
      case [.Selected] where selectedTintColor != nil:                  color = selectedTintColor!
      case [.Highlighted] where highlightedTintColor != nil:            color = highlightedTintColor!
      default:                                                          color = tintColor
    }
    return color
  }

  private weak var _currentTintColor: UIColor? { didSet { if _currentTintColor != oldValue { setNeedsDisplay() } } }
  public var currentTintColor: UIColor! { return _currentTintColor ?? tintColor }

  /** refresh */
  public func refresh() { _currentTintColor = tintColorForState(state) }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame) }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeBool(toggle, forKey: "toggle")
    aCoder.encodeObject(selectedTintColor,    forKey:"selectedTintColor")
    aCoder.encodeObject(highlightedTintColor, forKey:"highlightedTintColor")
    aCoder.encodeObject(disabledTintColor,    forKey:"disabledTintColor")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    toggle = aDecoder.decodeBoolForKey("toggle")
    selectedTintColor    = aDecoder.decodeObjectForKey("selectedTintColor")    as? UIColor
    highlightedTintColor = aDecoder.decodeObjectForKey("highlightedTintColor") as? UIColor
    disabledTintColor    = aDecoder.decodeObjectForKey("disabledTintColor")    as? UIColor
  }
  
}