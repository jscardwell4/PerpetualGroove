//
//  Slider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit
import MoonKit


let valueInterval: ClosedInterval<Float> = 24 ... 400
let touchInterval: ClosedInterval<Float> = 0 ... 119

let value: Float = 120
let delta: Float = -83

let valueNormalized = valueInterval.normalizeValue(value)
let valueInTouchInterval = touchInterval.valueForNormalizedValue(valueNormalized)
let newValueInTouchInterval = valueInTouchInterval + delta
let newValueNormalized = touchInterval.normalizeValue(newValueInTouchInterval)
let newValueInValueInterval = valueInterval.valueForNormalizedValue(newValueNormalized)

valueInterval.mapValue(touchInterval.mapValue(value, from: valueInterval) + 7, from: touchInterval)

func adjustValue(value: Float, forDelta delta: CGPoint) -> Float {
  let (deltaX, deltaY) = delta.unpack
  let  delta = Float(deltaX) * (1 / max(1, pow(log(abs(Float(pow(Double(deltaY), 2)))), Float(M_E)))) //(1 / log(Float(pow(M_E, Double(max(1, abs(deltaY)))))))
  let result = valueInterval.mapValue(touchInterval.mapValue(value, from: valueInterval) + delta, from: touchInterval)
  return result
}

for i in Range<Int>(start: 1, end: 100) {
  let p = CGPoint(x: CGFloat(delta), y: CGFloat(-i))
  adjustValue(value, forDelta: p)
}