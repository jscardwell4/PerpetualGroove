//
//  MultiselectGestureRecognizer.swift
//  Remote
//
//  Created by Jason Cardwell on 11/12/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit

public class MultiselectGestureRecognizer: UIGestureRecognizer {

  var firstTouchDate: NSDate?
  var registeredTouches: OrderedSet<UITouch> = []
  var anchoringTouches: OrderedSet<UITouch> = []
  var touchLocations: OrderedSet<CGPoint> = []
  var potentialAnchoringTouches: [UITouch] = []

  public var tolerance: NSTimeInterval = 0.0
  public var maximumNumberOfTouches = 1
  public var minimumNumberOfTouches = 1
  public var numberOfAnchorTouchesRequired = 0

  /**
  touchedSubviewsInView:includeView:

  - parameter view: UIView
  - parameter includeView: (UIView) -> Bool

  - returns: OrderedSet<UIView>
  */
  public func touchedSubviewsInView(view: UIView, includeView: (UIView) -> Bool) -> OrderedSet<UIView> {
    var views: OrderedSet<UIView> = []
    for location in touchLocationsInView(view) {
      if let v = view.hitTest(location, withEvent: nil) {
        if includeView(v) { views.append(v) }
      }
    }
    return views
  }

  /**
  touchedSubviewsInView:

  - parameter view: UIView

  - returns: OrderedSet<UIView>
  */
  public func touchedSubviewsInView(view: UIView) -> OrderedSet<UIView> { return touchedSubviewsInView(view){_ in true} }

  /**
  touchLocationsInView:

  - parameter view: UIView

  - returns: [CGPoint]
  */
  public func touchLocationsInView(view: UIView) -> [CGPoint] { return touchLocations.array.map{view.convertPoint($0, fromView: nil)} }

  /** reset */
  public override func reset() {
    super.reset()
    touchLocations.removeAll()
    anchoringTouches.removeAll()
    registeredTouches.removeAll()
    firstTouchDate = nil
    state = .Possible
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: NSSet
  - parameter event: UIEvent
  */
  override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {

    // ???: Why aren't we setting state to .Began?

    let beginningTouches = OrderedSet((touches as NSSet).allObjects as! [UITouch])
    registeredTouches ∪= beginningTouches

    if registeredTouches.count > maximumNumberOfTouches + numberOfAnchorTouchesRequired { state = .Failed; return }

    if firstTouchDate == nil { firstTouchDate = NSDate() }

    if anchoringTouches.count < numberOfAnchorTouchesRequired {
      if beginningTouches.count != numberOfAnchorTouchesRequired { state = .Failed; return }
      anchoringTouches ∪= beginningTouches
    }

    touchLocations ∪= (beginningTouches ∖ anchoringTouches).map{$0.locationInView(nil)}

  }

  /**
  touchesMoved:withEvent:

  - parameter touches: NSSet
  - parameter event: UIEvent
  */
  public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
    let movedTouches = OrderedSet((touches as NSSet).allObjects as! [UITouch])
    registeredTouches ∪= movedTouches
    let movedAnchors = anchoringTouches ∩ movedTouches
    if movedAnchors.count > 0 {
      let invalidAnchors = movedAnchors.filter {
        let delta = $0.previousLocationInView(nil) - $0.locationInView(nil)
        let distance = sqrtf(powf(Float(delta.x), 2.0) + powf(Float(delta.y), 2.0))
        return distance > 5.0
      }
      if invalidAnchors.count > 0 { state = .Failed; return }
    }
    touchLocations ∪= movedTouches.map{$0.locationInView(nil)}
    state = .Changed
  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: NSSet
  - parameter event: UIEvent
  */
  public override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent) { state = .Cancelled }

  /**
  touchesEnded:withEvent:

  - parameter touches: NSSet
  - parameter event: UIEvent
  */
  public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
    anchoringTouches ∖= (touches as NSSet).allObjects as! [UITouch]
    registeredTouches ∖= (touches as NSSet).allObjects as! [UITouch]

    if anchoringTouches.count == 0 {
      state = touchLocations.count > 0 && NSDate().timeIntervalSinceDate(firstTouchDate!) > tolerance ? .Ended : .Failed
    }
  }

}
