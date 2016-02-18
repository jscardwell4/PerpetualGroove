import Foundation
import MoonKit
import XCPlayground

let v = CGVector(dx: 144, dy: 144)
v.angle
v.angle.degrees
let Θ = π / 2
let dxʹ = v.dx * cos(Θ) - v.dy * sin(Θ)
let dyʹ = v.dx * sin(Θ) + v.dy * cos(Θ)
let vʹ = CGVector(dx: dxʹ, dy: dyʹ)
let vʺ = v.rotate(Θ)
let anotherV = v.rotateTo(-π/4)
anotherV.angle.degrees
vʹ.angle.degrees
(π/4).degrees
var path = UIBezierPath()
path.moveToPoint(.zero)
path.addLineToPoint(CGPoint(v))

path.applyTransform(CGAffineTransform(angle: π/2))

var path2 = UIBezierPath()
path2.moveToPoint(.zero)
path2.addLineToPoint(CGPoint(x: dxʹ, y: dyʹ))
