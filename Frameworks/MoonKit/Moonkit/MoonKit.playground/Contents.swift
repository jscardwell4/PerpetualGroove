import Foundation
import UIKit
import CoreText
import MoonKit
import Eveleth
import Chameleon

enum Setting: String, EnumerableType {
  case ICloudStorage = "iCloudStorage"
  case ConfirmDelete = "confirmDelete"
  case ScrollTrackLabels = "scrollTrackLabels"
  case CurrentDocument = "currentDocument"

  func currentValue<T>() -> T? {
    guard let value = NSUserDefaults.standardUserDefaults().objectForKey(rawValue) else { return nil }
    if T.self == Bool.self, let number = value as? NSNumber {
      return number.boolValue as? T
    } else if T.self == Double.self, let number = value as? NSNumber {
      return number.doubleValue as? T
    } else if T.self == NSURL.self, let url = value as? NSURL {
      return url as? T
    } else {
      return nil
    }
  }
  static var allCases: [Setting] { return [.ICloudStorage, .ConfirmDelete, .ScrollTrackLabels, .CurrentDocument] }
}
