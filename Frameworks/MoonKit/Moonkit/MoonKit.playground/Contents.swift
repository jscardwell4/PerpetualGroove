import Foundation
import UIKit
import MoonKit

var d = 120.0

withUnsafePointer(&d) {
  $0.memory
}