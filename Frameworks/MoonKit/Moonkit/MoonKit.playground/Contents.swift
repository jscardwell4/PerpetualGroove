import Foundation
import UIKit
import MoonKit

let size = CGSize(square: 200)
let path = UIBezierPath(ovalInRect: CGRect(size: size))
let innerSize = CGSize(square: size.width * 0.125)
path.moveToPoint(CGPoint(x: half(size.width) + innerSize.width, y: half(size.height)))
path.usesEvenOddFillRule = true
path.addArcWithCenter(CGPoint(x: half(size.width), y: half(size.height)), radius: innerSize.width, startAngle: 0, endAngle: π * 2, clockwise: true)
path.containsPoint(CGPoint(x: 100, y: 100))
path.containsPoint(CGPoint(x: 150, y: 150))