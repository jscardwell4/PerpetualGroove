import Foundation
import MoonKit

let x1:  CGFloat =  143.2811126708984
let y1:  CGFloat =  206.8070373535156
let dx: CGFloat =  144.9763520779608
let dy: CGFloat = -223.4146814806358

let m = dy/dx

// y2 - y1 = m * (x2 - x1)
var x2: CGFloat = 426
var y2 = m * (x2 - x1) + y1

y2 = 21
x2 = (y2 - y1) / m + x1

let p1 = CGPoint(x: x1, y: y1)
let p2 = CGPoint(x: x2, y: y2)
let d = p1.distanceTo(p2)
let modifier: CGFloat = 1 / 100
d / m * modifier
p2.distanceTo(p1)

abs(NSTimeInterval(p1.distanceTo(p2) / m * 0.01))
