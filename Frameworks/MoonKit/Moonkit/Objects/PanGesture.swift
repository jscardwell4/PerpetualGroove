//
//  PanGesture.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/23/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
//import UIKit.UIGestureRecognizerSubclass

public class PanGesture: ConfiningBlockActionGesture {

  // MARK: - Struct to specify upon which axis or axes panning touches are to be tracked
  public struct Axis : OptionSetType {
    public let rawValue: Int
    public init(rawValue: Int) {
      switch rawValue {
        case 1 ... 3:   self.rawValue = rawValue
        default:        self.rawValue = 3
      }
    }

    public static let Vertical = Axis(rawValue: 1)
    public static let Horizontal = Axis(rawValue: 2)

    public static let Default: Axis = [Vertical, Horizontal]

    public init(slope: CGFloat) {
      switch slope {
        case 0:                      self = .Horizontal
        case CGFloat.NaN:            self = .Vertical
        case let m where abs(m) < 1: self = .Horizontal
        case let m where abs(m) > 1: self = .Vertical
        default:                     self = .Default
      }
    }
  }

  public var axis = Axis.Default

  // MARK: - A simple structure for holding timestamp, centroid, and velocity data

  private struct TrackingData: CustomStringConvertible {
    var timestamp: NSTimeInterval = 0
    var centroid: CGPoint = nil
    var velocity: CGVector = nil
    var isValid: Bool { return centroid.isNull == false }
    mutating func reset() { timestamp = 0; centroid = nil; velocity = nil }
    init(timestamp: NSTimeInterval? = nil, centroid: CGPoint? = nil, velocity: CGVector? = nil) {
      if let timestamp = timestamp { self.timestamp = timestamp }
      if let centroid = centroid { self.centroid = centroid }
      if let velocity = velocity { self.velocity = velocity }
    }
    var description: String { return "{timestamp: \(timestamp); centroid: \(centroid); velocity: \(velocity)}" }
  }

  // MARK: - A simple structure for holding centroids capable of calculating the slope of a regression line

  private struct RegressionData: CustomStringConvertible {
    var points: [CGPoint] = []
    var slope: CGFloat {
      guard points.count > 0 else { return 0 }
      let n = CGFloat(points.count)
      let sumX = points.reduce(0) {$0 + $1.x}
      let sumY = points.reduce(0) {$0 + $1.y}
      let sumXX = points.reduce(0) {$0 + pow($1.x, 2)}
      let sumXY = points.reduce(0) {$0 + $1.x * $1.y}
      let numerator = n * sumXY - sumX * sumY
      let denominator = n * sumXX - pow(sumX, 2)
      return numerator / denominator
    }
    mutating func reset() { points.removeAll() }
    var description: String {
      return "{points: \(points); slope: \(slope)}"
    }
  }

  /**
  Returns `p`, {p.x, 0}, or {0, p.y} depending on the value of `axis`

  - parameter p: CGPoint

  - returns: CGPoint
  */
  private func filteredPoint(p: CGPoint) -> CGPoint {
    switch axis {
      case Axis.Vertical:   return CGPoint(x: 0, y: p.y)
      case Axis.Horizontal: return CGPoint(x: p.x, y: 0)
      default:              return p
    }
  }

  /**
  Returns `v`, {v.dx, 0}, or {0, v.dy} depending on the value of `axis`

  - parameter v: CGVector

  - returns: CGVector
  */
  private func filteredVector(v: CGVector) -> CGVector {
    switch axis {
    case Axis.Vertical:   return CGVector(dx: 0, dy: v.dy)
    case Axis.Horizontal: return CGVector(dx: v.dx, dy: 0)
    default:              return v
    }
  }

  /// MARK: - Mimicking UIPanGestureRecognizer
  ////////////////////////////////////////////////////////////////////////////////

  /**
  The minimum number of fingers that can be touching the view for this gesture to be recognized.

  The default value is `1`
  */
  public var minimumNumberOfTouches: Int = 1 { didSet { minimumNumberOfTouches  = max(1, min(10, minimumNumberOfTouches)) } }

  /**
  The maximum number of fingers that can be touching the view for this gesture to be recognized.

  The default value is `10`.
  */
  public var maximumNumberOfTouches: Int = 10 { didSet { maximumNumberOfTouches = max(1, min(10, maximumNumberOfTouches)) } }

  /**
  The translation of the pan gesture in the coordinate system of the specified view.

  The x and y values report the total translation over time. They are not delta values from the last time that the translation
  was reported. Apply the translation value to the state of the view when the gesture is first recognized—do not concatenate the
  value each time the handler is called.

  - parameter v: UIView? = nil The view in whose coordinate system the translation of the pan gesture should be computed. If you
  want to adjust a view's location to keep it under the user's finger, request the translation in that view's superview's 
  coordinate system.

  - returns: CGPoint A point identifying the new location of a view in the coordinate system of its designated superview.
  */
  public func translationInView(var v: UIView? = nil) -> CGPoint {
    if v == nil { v = view }
    let initial = v == view
                    ? initialData.centroid
                    : v!.convertPoint(initialData.centroid, fromView: view)
    let centroid = v == view
                     ? currentData.centroid
                     : v!.convertPoint(currentData.centroid, fromView: view)
    return filteredPoint(centroid - initial)
  }

  /**
  The velocity of the pan gesture in the coordinate system of the specified view.

  - parameter view: UIView! The view in whose coordinate system the velocity of the pan gesture is computed.

  - returns: CGVector The velocity of the pan gesture, which is expressed in points per second. The velocity is broken into
  horizontal and vertical components.
  */
  public func velocityInView(view: UIView) -> CGVector { return filteredVector(currentData.velocity) }


  /// MARK: -

  public var requiredMovement: CGFloat = 10.0

  private var panningTouches: Set<UITouch> = []

  private var initialData  = TrackingData()
  private var currentData  = TrackingData()
  private var previousData = TrackingData()

  private var regressionData = RegressionData()

  /** updateData */
  private func updateData() {
    // Make sure when can grab a timestamp from the panning touches
    guard let timestamp = panningTouches.map({$0.timestamp}).maxElement() else { return }

    // Create a data structure with an updated timestamp and centroid
    let data = TrackingData(timestamp: timestamp, centroid: centroidForTouches(panningTouches))

    // Append the new centroid to our regression data
    regressionData.points.append(data.centroid)

    // Check if pan is moving along a compatible axis
    guard regressionData.points.count < 2 || axis.isSupersetOf(Axis(slope: regressionData.slope)) else {
      state = .Failed
      return
    }

    // Encapsulate velocity calculation to stay DRY in the switch statement to follow
    let velocity: () -> CGVector = {
      let deltaCentroid = self.currentData.centroid - self.previousData.centroid
      let deltaTimestamp = CGFloat(self.currentData.timestamp - self.previousData.timestamp)
      return CGVector(deltaCentroid / deltaTimestamp)
    }

    // Switch on the current state to update data structures appropriately
    switch state {

      case .Possible where initialData.isValid:
        if filteredPoint(initialData.centroid - data.centroid).absolute.max >= requiredMovement {
          previousData = initialData
          currentData = data
          currentData.velocity = velocity()
          state = .Began
        }

      case .Possible:
        initialData = data

      case .Began, .Changed:
        previousData = currentData
        currentData = data
        currentData.velocity = velocity()
        if filteredVector(currentData.velocity).absolute.max > 0 {
          state = .Changed
        }

      case .Ended, .Failed, .Cancelled:
        break

    }

  }

  /// MARK: - UIGestureRecognizer
  ////////////////////////////////////////////////////////////////////////////////

 /** reset */
  public override func reset() {
    state = .Possible
    panningTouches.removeAll()
    initialData.reset()
    currentData.reset()
    previousData.reset()
    regressionData.reset()
  }

  /**
  touchesBegan:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent
  */
  public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
    guard panningTouches.count == 0
      && (minimumNumberOfTouches ... maximumNumberOfTouches).contains(touches.count)
      && validateTouchLocations(touches, withEvent: event) else { state = .Failed; return }

    panningTouches = touches
    updateData()
  }

  /**
  touchesMoved:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent
  */
  public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
    guard panningTouches.isSubsetOf(touches) else { return }
    guard validateTouchLocations(panningTouches, withEvent: event) else { state = .Failed; return }
    updateData()

    // TODO: move to failed state if movement is in the wrong direction

  }

  /**
  touchesCancelled:withEvent:

  - parameter touches: Set<UITouch>
  - parameter event: UIEvent
  */
  public override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent) {
    guard panningTouches.intersect(touches).count > 0 else { return }
    state = .Cancelled
  }

  /**
  touchesEnded:withEvent:

  - parameter touches: NSSet
  - parameter event: UIEvent
  */
  public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
    guard panningTouches.intersect(touches).count > 0 else { return }
    guard validateTouchLocations(panningTouches, withEvent: event) else { state = .Failed; return }

    if centroidForTouches(panningTouches) != currentData.centroid { updateData() }
    if state != .Failed {
      state = .Ended
    }
  }
}
