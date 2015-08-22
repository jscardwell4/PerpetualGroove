//: Playground - noun: a place where people can play
import Foundation
import UIKit
import MoonKit
import CoreAudio
import CoreMIDI
import SpriteKit

let size = CGSize(square: 32)
let bounds = CGRect(size: CGSize(width: 200, height: 44))
let maximumValue = Float(380)
let value = Float(120)
var origin = CGPoint(x: -half(size.width), y: half(bounds.height) - half(size.height))
let ratio = Ratio(numerator: CGFloat(Ratio(CGFloat(maximumValue), bounds.width).numeratorForDenominator(bounds.width + size.width)), denominator: CGFloat(maximumValue))
let displayValue = ratio.value * CGFloat(value)