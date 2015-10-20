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

  @IBInspectable public var normalTintColor:      UIColor? { didSet { refresh() } }
  @IBInspectable public var highlightedTintColor: UIColor? { didSet { refresh() } }
  @IBInspectable public var disabledTintColor:    UIColor? { didSet { refresh() } }
  @IBInspectable public var selectedTintColor:    UIColor? { didSet { refresh() } }

  // MARK: - State

  public override var enabled:     Bool { didSet { guard enabled     != oldValue else { return }; refresh() } }
  public override var highlighted: Bool { didSet { guard highlighted != oldValue else { return }; refresh() } }
  public override var selected:    Bool { didSet { guard selected    != oldValue else { return }; refresh() } }

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
      default:                                                          color = normalTintColor ?? tintColor
    }
    return color
  }

  /** refresh */
  public func refresh() { tintColor = tintColorForState(state) }

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
    aCoder.encodeObject(normalTintColor,      forKey:"normalTintColor")
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
    normalTintColor      = aDecoder.decodeObjectForKey("normalTintColor")      as? UIColor
    selectedTintColor    = aDecoder.decodeObjectForKey("selectedTintColor")    as? UIColor
    highlightedTintColor = aDecoder.decodeObjectForKey("highlightedTintColor") as? UIColor
    disabledTintColor    = aDecoder.decodeObjectForKey("disabledTintColor")    as? UIColor
    refresh()
  }
  
}