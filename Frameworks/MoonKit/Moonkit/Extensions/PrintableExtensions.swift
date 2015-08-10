//
//  PrintableExtensions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/27/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension NSFetchedResultsChangeType: CustomStringConvertible {
  public var description: String {
    switch self {
      case .Insert: return "Insert"
      case .Delete: return "Delete"
      case .Move:   return "Move"
      case .Update: return "Update"
    }
  }
}

extension UIBlurEffectStyle: CustomStringConvertible { public var description: String { return self == .Dark ? "Dark" : "Light" } }