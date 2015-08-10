//
//  NSIndexSet+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/26/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

extension NSIndexSet {

  public convenience init(range: Range<Int>) {
    self.init(indexesInRange: NSRange(location: range.startIndex, length: range.endIndex - range.startIndex))
  }

}