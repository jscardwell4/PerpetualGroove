//
//  UIImage+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/26/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

extension UIImageOrientation: CustomStringConvertible {
  public var description: String {
    switch self {
    case .Up:            return "Up"
    case .Down:          return "Down"
    case .Left:          return "Left"
    case .Right:         return "Right"
    case .UpMirrored:    return "UpMirrored"
    case .DownMirrored:  return "DownMirrored"
    case .LeftMirrored:  return "LeftMirrored"
    case .RightMirrored: return "RightMirrored"
    }
  }
}

typealias BuggyCIImage = CIImage
extension UIImage {
  public func heightScaledToWidth(width: CGFloat) -> CGFloat {
    let (w, h) = size.unpack
    let ratio = Ratio(w, h)
    return ratio.denominatorForNumerator(width)
  }

  public func imageWithColor(color: UIColor) -> UIImage {
    guard let image = BuggyCIImage(image: self) else { return self }
    return UIImage(CIImage: BuggyCIImage(color: CIColor(color: color)).imageByApplyingFilter("CISourceInCompositing",
                                                         withInputParameters: ["inputBackgroundImage": image]),
                   scale: scale,
                   orientation: imageOrientation)
  }
}