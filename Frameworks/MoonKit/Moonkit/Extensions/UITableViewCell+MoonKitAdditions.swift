//
//  UITableViewCell+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/21/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewCell {
  public var tableView: UITableView? {
    var tableView: UITableView?
    var currentView: UIView? = superview
    while tableView == nil && currentView != nil {
      tableView = currentView as? UITableView
      currentView = currentView?.superview
    }
    return tableView
  }
}
