//: Playground - noun: a place where people can play

import Foundation
import UIKit
import MoonKit
import XCPlayground

let picker = InlinePickerView(frame: CGRect(size: CGSize(width: 191, height: 44)))
picker.backgroundColor = UIColor.yellowColor()
picker.labels = ["No Manufacturer", "Dish", "Samsung", "Sony"]
picker.setNeedsDisplay()

//XCPShowView("picker", view: picker)
picker.backgroundColor = UIColor.yellowColor()
