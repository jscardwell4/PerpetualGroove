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


let bezierPath = UIBezierPath(arcCenter: CGPoint(x: 100, y: 100), radius: 50, startAngle: π / 4, endAngle: -π - π / 4, clockwise: false)
bezierPath.addLineToPoint(CGPoint(x: 100, y: 100))
bezierPath.closePath()

let knob = Knob(frame: CGRect(x: 0, y: 0, width: 200, height: 200))