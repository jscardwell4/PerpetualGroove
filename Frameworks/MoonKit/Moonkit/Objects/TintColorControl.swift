//
//  TintColorControl.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/20/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class TintColorControl: UIControl {

  // MARK: - Colors

  public override var tintColor: UIColor! {
    didSet { if normalTintColor == nil { normalTintColor = tintColor } }
  }

  @IBInspectable public var normalTintColor:           UIColor? { didSet { refresh() } }
  @IBInspectable public var highlightedTintColor:      UIColor? { didSet { refresh() } }
  @IBInspectable public var disabledTintColor:         UIColor? { didSet { refresh() } }
  @IBInspectable public var selectedTintColor:         UIColor? { didSet { refresh() } }
  @IBInspectable public var disabledSelectedTintColor: UIColor? { didSet { refresh() } }

  // MARK: - State

  public override var enabled:     Bool { get { return super.enabled }     set { super.enabled     = newValue; refresh() } }
  public override var highlighted: Bool { get { return super.highlighted } set { super.highlighted = newValue; refresh() } }
  public override var selected:    Bool { get { return super.selected }    set { super.selected    = newValue; refresh() } }

  /**
  tintColorForState:

  - parameter state: UIControlState

  - returns: UIColor
  */
  private func tintColorForState(state: UIControlState) -> UIColor {
    let color: UIColor
    switch state {
      case [.Disabled, .Selected] where disabledSelectedTintColor != nil: color = disabledSelectedTintColor!
      case [.Disabled]            where disabledTintColor         != nil: color = disabledTintColor!
      case [.Selected]            where selectedTintColor         != nil: color = selectedTintColor!
      case [.Highlighted]         where highlightedTintColor      != nil: color = highlightedTintColor!
      default:                                                            color = normalTintColor ?? tintColor
    }
    return color
  }

  /** refresh */
  public func refresh() { tintColor = tintColorForState(state); setNeedsDisplay() }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); normalTintColor = tintColor }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeObject(normalTintColor,           forKey:"normalTintColor")
    aCoder.encodeObject(selectedTintColor,         forKey:"selectedTintColor")
    aCoder.encodeObject(highlightedTintColor,      forKey:"highlightedTintColor")
    aCoder.encodeObject(disabledTintColor,         forKey:"disabledTintColor")
    aCoder.encodeObject(disabledSelectedTintColor, forKey:"disabledSelectedTintColor")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    normalTintColor           = aDecoder.decodeObjectForKey("normalTintColor")           as? UIColor
    selectedTintColor         = aDecoder.decodeObjectForKey("selectedTintColor")         as? UIColor
    highlightedTintColor      = aDecoder.decodeObjectForKey("highlightedTintColor")      as? UIColor
    disabledTintColor         = aDecoder.decodeObjectForKey("disabledTintColor")         as? UIColor
    disabledSelectedTintColor = aDecoder.decodeObjectForKey("disabledSelectedTintColor") as? UIColor
    if normalTintColor == nil { normalTintColor = tintColor }
    refresh()
  }
  
}