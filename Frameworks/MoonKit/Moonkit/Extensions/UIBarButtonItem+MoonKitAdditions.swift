//
//  UIBarButtonItem+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/22/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public extension UIBarButtonItem {

  class func fixedSpace(width: CGFloat) -> UIBarButtonItem {
    let item = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil);
    item.width = width
    return item
  }

  class func flexibleSpace() -> UIBarButtonItem {
    return UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
  }

  convenience init(imageNamed: String, style: UIBarButtonItemStyle, target: AnyObject?, action: Selector) {
    self.init(image: UIImage(named: imageNamed), style: style, target: target, action: action)
  }

}