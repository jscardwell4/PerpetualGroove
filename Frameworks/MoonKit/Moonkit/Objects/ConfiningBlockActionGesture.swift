//
//  ConfiningBlockActionGesture.swift
//  Remote
//
//  Created by Jason Cardwell on 11/19/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
//import UIKit.UIGestureRecognizerSubclass

public class ConfiningBlockActionGesture: BlockActionGesture {

  public var confineToView: Bool = false

  /**
  validateTouchLocations:withEvent:

  - parameter touches: C
  - parameter event: UIEvent

  - returns: Bool
  */
  func validateTouchLocations<C:CollectionType where C.Generator.Element == UITouch, C.Index.Distance == Int>(touches: C,
                    withEvent event: UIEvent) -> Bool
  {
    guard confineToView, let view = view else { return true }
    return touches.count == touches.filter({ view.pointInside($0.locationInView(view), withEvent: event) }).count
  }


}
