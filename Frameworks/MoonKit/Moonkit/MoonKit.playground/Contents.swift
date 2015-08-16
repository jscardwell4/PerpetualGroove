//: Playground - noun: a place where people can play
import Foundation
import UIKit
import MoonKit

let interval = ClosedInterval<Float>(0, 1)
interval.contains(Float(0.5))
interval.contains(Float(1.0))
interval.contains(Float(1.1))

