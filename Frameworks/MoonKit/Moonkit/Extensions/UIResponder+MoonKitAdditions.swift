//
//  UIResponder+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/8/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension UIResponder {

  /** toggleFirstResponder */
  public func toggleFirstResponder() {
    if isFirstResponder() { resignFirstResponder() }
    else if canBecomeFirstResponder() { becomeFirstResponder() }
  }

}