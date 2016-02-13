//
//  Playgrounds.swift
//  MoonKit
//
//  Created by Jason Cardwell on 2/8/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

public func measure(iterations: Int = 10, forBlock block:() -> Void) -> (mean: Double, variance: Double, total: Double, samples: [Double]) {
  precondition(iterations > 0, "Iterations must be a positive integer")

  var total = 0.0
  var samples: [Double] = []

  for _ in 0 ..< iterations {
    let start = NSDate.timeIntervalSinceReferenceDate()
    block()
    let took = NSDate.timeIntervalSinceReferenceDate() - start
    samples.append(took)
    total += took
  }

  let mean = total / Double(iterations)
  let deviation = samples.reduce(0.0) {$0 + pow($1 - mean, 2)}
  let variance = deviation / Double(iterations)

  return (mean, variance, total, samples)
}

