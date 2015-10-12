//
//  UIControlState+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension UIControlState: CustomStringConvertible {
  public var description: String {
    var result = "UIControlState {"
    var strings: [String] = []
    if self ∋ .Highlighted { strings.append("Highlighted") }
    if self ∋ .Selected { strings.append("Selected") }
    if self ∋ .Disabled { strings.append("Disabled") }
    if strings.isEmpty { strings.append("Normal") }
    result += ", ".join(strings)
    result += "}"
    return result
  }
}