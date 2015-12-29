import Foundation
import UIKit
import MoonKit

//player size: {489.70001220703125, 489.70001220703125}
//node: <Default> Loon Garden1; position: (63.9999923706055, 293.499969482422); velocity: (-244.170288085938, 130.756576538086); ticks: 0
//node: <Default> Loon Garden1; location: (31.4439506530762, 310.933776855469); velocity: (244.170288085938, 130.756576538086); ticks: 41
//node: <Default> Loon Garden1; location: (295.961608886719, 463.479705810547); velocity: (244.170288085938, -130.756576538086); ticks: 1042
//node: <Default> Loon Garden1; location: (456.706939697266, 381.757507324219); velocity: (-244.170288085938, -130.756576538086); ticks: 1559
//node: <Default> Loon Garden1; location: (29.4062519073486, 144.215637207031); velocity: (244.170288085938, -130.756576538086); ticks: 3436
//node: <Default> Loon Garden1; location: (234.916137695312, 25.44482421875); velocity: (244.170288085938, 130.756576538086); ticks: 4373

let minX: CGFloat = 25
let minY: CGFloat = 25
let maxX: CGFloat = 489.70001220703125 - 25
let maxY: CGFloat = 489.70001220703125 - 25

let tpb: CGFloat = 480
let bpm: CGFloat = 120
let bps: CGFloat = bpm / 60
let tps: CGFloat = bps * tpb

let p1 = CGPoint(x: 63.9999923706055, y: 293.499969482422)
let p2 = CGPoint(x: 31.4439506530762, y: 310.933776855469)
let p3 = CGPoint(x: 295.961608886719, y: 463.479705810547)
let p4 = CGPoint(x: 456.706939697266, y: 381.757507324219)
let p5 = CGPoint(x: 29.4062519073486, y: 144.215637207031)
let p6 = CGPoint(x: 234.916137695312, y: 25.44482421875)

let t1 = 0
let t2 = 41
let t3 = 1042
let t4 = 1559
let t5 = 3436
let t6 = 4373

let v1 = CGVector(dx: -244.170288085938, dy:  130.756576538086)
let v2 = CGVector(dx:  244.170288085938, dy:  130.756576538086)
let v3 = CGVector(dx:  244.170288085938, dy: -130.756576538086)
let v4 = CGVector(dx: -244.170288085938, dy: -130.756576538086)
let v5 = CGVector(dx:  244.170288085938, dy: -130.756576538086)
let v6 = CGVector(dx:  244.170288085938, dy:  130.756576538086)

struct Line: CustomStringConvertible {
  var m: CGFloat { return dy / dx } /// slope of the line
  var b: CGFloat                    /// y intercept of the line
  var v: CGVector                   /// velocity in units per second
  var dx: CGFloat { return v.dx }   /// horizontal velocity in units per second
  var dy: CGFloat { return v.dy }   /// vertical velocity in units per second

  init(vector: CGVector, point p: CGPoint) { v = vector; b = p.y - (v.dy / v.dx) * p.x }

  func pointAtX(x: CGFloat) -> CGPoint { return CGPoint(x: x, y: m * x + b) }

  func pointAtY(y: CGFloat) -> CGPoint { return CGPoint(x: (y - b) / m, y: y) }

  func timeFromX(x1: CGFloat, toX x2: CGFloat) -> CGFloat {
    return (x2 - x1) / dx
  }

  func timeFromY(y1: CGFloat, toY y2: CGFloat) -> CGFloat {
    return (y2 - y1) / dy
  }

  var description: String { return "y = \(m)x + \(b)" }
}

let l1 = Line(vector: v1, point: p1)
l1.timeFromX(p1.x, toX: minX) * tps

let l2 = Line(vector: v2, point: p2)
l2.timeFromX(p2.x, toX: maxX) * tps
l2.timeFromY(p2.y, toY: maxY) * tps
l2.pointAtX(maxX)
l2.pointAtY(maxY)

let l3 = Line(vector: v3, point: p3)
let l4 = Line(vector: v4, point: p4)
let l5 = Line(vector: v5, point: p5)
let l6 = Line(vector: v6, point: p6)
