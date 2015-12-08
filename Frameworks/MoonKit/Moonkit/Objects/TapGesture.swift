//
//  TapGesture.swift
//  MoonKit
//
//  Created by Jason Cardwell on 12/7/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class TapGesture: UITapGestureRecognizer {

  public var callback: ((UITapGestureRecognizer) -> Void)?
  public override var state: UIGestureRecognizerState {
    didSet {
      if state == .Ended { callback?(self) }
    }
  }

  public convenience init(callback: (UITapGestureRecognizer) -> Void) {
    self.init()
    self.callback = callback
  }

}
