//
//  Character.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/23/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public extension Character {
  public var isWhitespace: Bool { return NSCharacterSet.whitespaceAndNewlineCharacterSet() ∋ self }
}