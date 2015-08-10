//
//  UIBezierPath+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/29/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

extension UIBezierPath {
  public convenience init(diamondInRect rect: CGRect) {
    self.init()
    moveToPoint(CGPoint(x: rect.minX, y: rect.minY + 0.5 * rect.height))
    addLineToPoint(CGPoint(x: rect.minX + 0.5 * rect.width, y: rect.minY))
    addLineToPoint(CGPoint(x: rect.minX + rect.width, y: rect.minY + 0.5 * rect.height))
    addLineToPoint(CGPoint(x: rect.minX + 0.5 * rect.width, y: rect.minY + rect.height))
    addLineToPoint(CGPoint(x: rect.minX, y: rect.minY + 0.5 * rect.height))
    closePath()
  }

  public convenience init(triangleInRect rect: CGRect) {
    self.init()
    moveToPoint(CGPoint(x: rect.minX + 0.50 * rect.width, y: rect.minY))
    addLineToPoint(CGPoint(x: rect.minX + 0.75 * rect.width, y: rect.minY + 0.5 * rect.height))
    addLineToPoint(CGPoint(x: rect.minX + rect.width, y: rect.minY + rect.height))
    addLineToPoint(CGPoint(x: rect.minX + 0.50 * rect.width, y: rect.minY + rect.height))
    addLineToPoint(CGPoint(x: rect.minX, y: rect.minY + rect.height))
    addLineToPoint(CGPoint(x: rect.minX + 0.25 * rect.width, y: rect.minY + 0.5 * rect.height))
    addLineToPoint(CGPoint(x: rect.minX + 0.5 * rect.width, y: rect.minY))
    closePath()
  }
}