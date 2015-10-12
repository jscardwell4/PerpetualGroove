//
//  WeakObject.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public struct WeakObject<T:AnyObject> {
  public private(set) weak var value: T?
  public init(_ v: T) { value = v }
}