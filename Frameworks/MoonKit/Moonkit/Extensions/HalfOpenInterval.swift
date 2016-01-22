//
//  HalfOpenInterval.swift
//  MoonKit
//
//  Created by Jason Cardwell on 1/19/16.
//  Copyright © 2016 Jason Cardwell. All rights reserved.
//

import Foundation

extension HalfOpenInterval where Bound:SignedNumberType {
  public var length: Bound { return end - start }
}