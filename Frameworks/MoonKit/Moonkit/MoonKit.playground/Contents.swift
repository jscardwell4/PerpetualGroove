import Foundation
import UIKit
import MoonKit

let knob = Knob(frame: CGRect(size: CGSize(square: 200)))
knob.minimumValue = -1
knob.maximumValue = 1
knob.value = 1


knob.setNeedsDisplay()

knob