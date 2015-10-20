//
//  ToggleControl.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class ToggleControl: TintColorControl {

  // MARK: - Toggling

  // TODO: Make this work again
  /// Whether changes to `highlighted` should toggle `selected`
  @IBInspectable public var toggle: Bool = false

  private var toggleBegan = false

  public override var highlighted: Bool {
    didSet {
      guard highlighted != oldValue else { return }
      if toggle && toggleBegan && !highlighted { selected.toggle() }
      else if toggle && !toggleBegan && highlighted { toggleBegan = true }
    }
  }



  /// Overridden to implement optional toggling
  public override var selected: Bool { didSet { if selected != oldValue { toggleBegan = false } } }

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
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    toggle = aDecoder.decodeBoolForKey("toggle")
  }
  
}