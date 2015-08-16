//
//  ClosedInterval+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/16/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension ClosedInterval {
  public func clampValue(value: Bound) -> Bound {
    if contains(value) { return value }
    else if start > value { return start }
    else { return end }
  }
}