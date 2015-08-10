//
//  Dispatch.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/3/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public func secondsToNanoseconds(seconds: Double) -> UInt64 { return UInt64(seconds * Double(NSEC_PER_SEC)) }

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