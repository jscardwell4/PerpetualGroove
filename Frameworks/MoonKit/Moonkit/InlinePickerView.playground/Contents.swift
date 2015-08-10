//: Playground - noun: a place where people can play

import UIKit
import MoonKit

let picker = InlinePickerView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
picker.backgroundColor = UIColor.whiteColor()
//picker.labels = ["No Manufacturer", "Dish", "Samsung", "Sony"]
picker.reloadData()
picker.setNeedsDisplay()
picker
