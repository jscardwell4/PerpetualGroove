//
//  Timer.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/3/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation


public final class Timer {

  private let queue: dispatch_queue_t
  private let source: dispatch_source_t

  public var interval: UInt64 { didSet { updateTimer() } }
  public var leeway: UInt64  { didSet { updateTimer() } }
  public var handler: (() -> Void)?

  public private(set) var running = false
  private var handleEvents = true

  /** Starts the timer */
  public func start() { guard !running else { return }; updateTimer(); dispatch_resume(source); running = true }

  /** Stops the timer */
  public func stop() { guard running else { return }; dispatch_suspend(source); running = false }

  /** Sets the timer for `source` using the current property values */
  private func updateTimer() {
    dispatch_source_set_timer(source, dispatch_walltime(nil, Int64(interval)), interval, leeway)
  }

  /**
  init:interval:leeway:handler:

  - parameter q: dispatch_queue_t The queue used for the timer's event handler, defaults to main
  - parameter i: Double Double How often the timer should fire in seconds
  - parameter l: Double Allowable amount timer may be deferred in seconds
  - parameter h: ((Timer) -> Void Handler to execute every time the timer fires
  */
  public init(queue q: dispatch_queue_t = dispatch_get_main_queue(),
              interval i: UInt64 = secondsToNanoseconds(1),
              leeway l: UInt64 = 0,
              handler h: (() -> Void)? = nil)
  {
    queue = q; interval = i; leeway = l; handler = h
    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
    dispatch_source_set_event_handler(source) { [weak self] in if self?.handleEvents == true { self?.handler?() } }
  }

  /** Cancels the dispatch source if it has not already been cancelled */
  deinit {
    guard dispatch_source_testcancel(source) == 0 else { return }
    handleEvents = false
    if !running { dispatch_resume(source) }
    dispatch_source_cancel(source)
  }
}