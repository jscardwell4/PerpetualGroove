//
//  NSIndexPath+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 6/2/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension NSIndexPath {

  public convenience init(_ row: Int, _ section: Int) { self.init(forRow: row, inSection: section) }

}
