//
//  BlockActionGesture.swift
//  MSKit
//
//  Created by Jason Cardwell on 11/18/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
//import UIKit.UIGestureRecognizerSubclass

@objc public class BlockActionGesture: UIGestureRecognizer {

  private let handlerTarget = Handler()

  public var handler: ((BlockActionGesture) -> Void)? {
    get { return handlerTarget.action }
    set { handlerTarget.action = newValue }
  }

  private class Handler {
    var action: ((BlockActionGesture) -> Void)?
    private var timestamp: dispatch_time_t = 0

    /** dispatchHandler */
    func dispatchHandler(sender: BlockActionGesture) {
      if secondsSince(timestamp) > 0.1 {
        timestamp = dispatch_time(DISPATCH_TIME_NOW, 0)
        action?(sender)
      }
    }

    /**
    secondsBetween:and:

    - parameter stamp1: dispatch_time_t
    - parameter stamp2: dispatch_time_t

    - returns: Double
    */
    private func secondsBetween(stamp1: dispatch_time_t, and stamp2: dispatch_time_t) -> Double {
      return (Double(stamp1) - Double(stamp2)) * Double(NSEC_PER_SEC)
    }

    /**
    secondsSince:

    - parameter stamp: dispatch_time_t

    - returns: Double
    */
    private func secondsSince(stamp: dispatch_time_t) -> Double {
      return secondsBetween(dispatch_time(DISPATCH_TIME_NOW, 0), and: stamp)
    }

  }

  /**
  centroidForTouches:

  - parameter touches: [UITouch]

  - returns: CGPoint
  */
  func centroidForTouches<C:CollectionType where C.Generator.Element == UITouch, C.Index.Distance == Int>
    (touches: C) -> CGPoint
  {
    guard touches.count > 0, let view = view else { return CGPoint.nullPoint }
    return touches.map {$0.locationInView(view)}.reduce(CGPoint.zeroPoint, combine: +) / CGFloat(touches.count)
  }

  /**
  initWithHandler:

  - parameter handler: (LongPressGesture) -> Void
  */
  public convenience init(handler: (BlockActionGesture) -> Void) {
    self.init()
    self.handler = handler
    addTarget(self, action: "dispatchHandler:")
  }

  /**
  dispatchHandler:

  - parameter sender: BlockActionGesture
  */
  public func dispatchHandler(sender: BlockActionGesture) { handlerTarget.dispatchHandler(sender) }

  public override var state: UIGestureRecognizerState { didSet { handlerTarget.dispatchHandler(self) } }

  /**
  initWithTarget:action:

  - parameter target: AnyObject
  - parameter action: Selector
  */
  public override init(target: AnyObject?, action: Selector) {
    super.init(target: target, action: action)
    addTarget(self, action: "dispatchHandler:")
  }

}
