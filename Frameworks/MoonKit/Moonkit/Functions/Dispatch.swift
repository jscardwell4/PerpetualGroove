//
//  Dispatch.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/3/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public func secondsToNanoseconds(seconds: Double) -> UInt64 { return UInt64(seconds * Double(NSEC_PER_SEC)) }
public func nanosecondsToSeconds(nanoseconds: UInt64) -> Double { return Double(nanoseconds) / Double(NSEC_PER_SEC) }

/**
createTimer:

- parameter queue: dispatch_queue_t The queue used for the timer's event handler, defaults to main
- parameter start: dispatch_time_t The time at which point the timer should start, defaults to now
- parameter interval: Double How often the timer should fire in seconds
- parameter leeway: Double Allowable amount timer may be deferred in seconds
- parameter handler: dispatch_block_t Handler to execute every time the timer fires

- returns: dispatch_source_t
*/
public func createTimer(queue: dispatch_queue_t = dispatch_get_main_queue(),
                        start: dispatch_time_t = dispatch_walltime(nil, 0),
                        interval: Double,
                        leeway: Double,
                        handler: dispatch_block_t) -> dispatch_source_t
{
  let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
  dispatch_source_set_timer(timer, start, secondsToNanoseconds(interval), secondsToNanoseconds(leeway))
  dispatch_source_set_event_handler(timer, handler)
  dispatch_resume(timer)
  return timer
}

/**
dispatchToMain:block:

- parameter synchronous: Bool = false
- parameter block: dispatch_block_t
*/
public func dispatchToMain(synchronous synchronous: Bool = false, _ block: dispatch_block_t) {
  if NSThread.isMainThread() { block() }
  else if synchronous { dispatch_sync(dispatch_get_main_queue(), block) }
  else { dispatch_async(dispatch_get_main_queue(), block) }
}


/**
serialQueueWithLabel:qualityOfService:relativePriority:

- parameter label: String
- parameter qos: qos_class_t = QOS_CLASS_DEFAULT
- parameter priority: Int32 = 0

- returns: dispatch_queue_t
*/
public func serialQueueWithLabel(label: String,
                qualityOfService qos: qos_class_t = QOS_CLASS_DEFAULT,
                relativePriority priority: Int32 = 0) -> dispatch_queue_t
{
  return dispatch_queue_create(Array(label.utf8).map({Int8($0)}),
                               dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, priority))
}

/**
concurrentQueueWithLabel:qualityOfService:relativePriority:

- parameter label: String
- parameter qos: qos_class_t = QOS_CLASS_DEFAULT
- parameter priority: Int32 = 0

- returns: dispatch_queue_t
*/
public func concurrentQueueWithLabel(label: String,
                    qualityOfService qos: qos_class_t = QOS_CLASS_DEFAULT,
                    relativePriority priority: Int32 = 0) -> dispatch_queue_t
{
  return dispatch_queue_create(Array(label.utf8).map({Int8($0)}),
                               dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, qos, priority))
}

public var globalBackgroundQueue: dispatch_queue_t { return dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0) }
public var globalUserInteractiveQueue: dispatch_queue_t { return dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0) }
public var globalUserInitiatedQueue: dispatch_queue_t { return dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0) }
public var globalUtilityQueue: dispatch_queue_t { return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0) }

/**
backgroundDispatch:

- parameter block: () -> Void
*/
public func backgroundDispatch(block: () -> Void) { dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block) }


public func delayedDispatch(delay: Double, _ queue: dispatch_queue_t, _ block: dispatch_block_t) {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, Int64(secondsToNanoseconds(delay))),
    dispatch_get_main_queue(),
    block
  )
}

/**
delayedDispatchToMain:block:

- parameter delay: Int
- parameter block: dispatch_block_t
*/
public func delayedDispatchToMain(delay: Double, _ block: dispatch_block_t) {
  delayedDispatch(delay, dispatch_get_main_queue(), block)
}

