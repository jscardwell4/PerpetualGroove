//
//  NSLayoutManager+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension NSLayoutManager {
  /**
  characterIndexForPoint:inTextContainer:

  - parameter point: CGPoint
  - parameter container: NSTextContainer

  - returns: Int
  */
  public func characterIndexForPoint(point: CGPoint, inTextContainer container: NSTextContainer) -> Int {
    return characterIndexForPoint(point, inTextContainer: container, fractionOfDistanceBetweenInsertionPoints: nil)
  }
}