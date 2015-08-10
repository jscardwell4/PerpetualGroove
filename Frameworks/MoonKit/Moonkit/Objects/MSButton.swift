//
//  MSButton.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/10/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class MSButton: UIButton {

  private var backgroundColors: [UInt:UIColor?] = [0:nil, 1:nil, 2:nil, 3:nil, 4:nil, 5:nil, 6:nil, 7:nil]

//  public override init() { super.init() }
  public override init(frame: CGRect) { super.init(frame: frame) }
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }


  /**
  setBackgroundColor:forState:

  - parameter color: UIColor?
  - parameter state: UIControlState
  */
  public func setBackgroundColor(color: UIColor?, forState state: UIControlState) {
    if (0...7).contains(state.rawValue) {
      backgroundColors[state.rawValue] = color
      if state == self.state { backgroundColor = color }
    }
  }

  /**
  backgroundColorForState:

  - parameter state: UIControlState

  - returns: UIColor?
  */
  public func backgroundColorForState(state: UIControlState) -> UIColor? {
    var color = backgroundColors[state.rawValue]!
    if color == nil && state.rawValue & UIControlState.Highlighted.rawValue == UIControlState.Highlighted.rawValue  {
      color = backgroundColors[UIControlState.Highlighted.rawValue]!
    }
    if color == nil && state.rawValue & UIControlState.Selected.rawValue == UIControlState.Selected.rawValue {
      color = backgroundColors[UIControlState.Selected.rawValue]!
    }
    if color == nil && state.rawValue & UIControlState.Disabled.rawValue == UIControlState.Disabled.rawValue {
      color = backgroundColors[UIControlState.Disabled.rawValue]!
    }
    if color == nil {
      color = backgroundColors[UIControlState.Normal.rawValue]!
    }
    return color
  }

  public override var backgroundColor: UIColor? {
    get {
      let color = backgroundColorForState(state)
      if super.backgroundColor != color { super.backgroundColor = color }
      return super.backgroundColor
    }
    set { super.backgroundColor = newValue }
  }

  override public var enabled: Bool { didSet { backgroundColor = backgroundColorForState(state) } }
  override public var selected: Bool { didSet { backgroundColor = backgroundColorForState(state) } }
  override public var highlighted: Bool { didSet { backgroundColor = backgroundColorForState(state) } }

}
