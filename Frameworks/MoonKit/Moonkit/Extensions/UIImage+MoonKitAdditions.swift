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
import class CoreImage.CIImage

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

private func imageFromImage(image: UIImage, color: UIColor) -> UIImage {
  guard let img = CIImage(image: image) else { return image }
  let context = CIContext(options: nil)
  let parameters = ["inputImage": CIImage(color: CIColor(color: color)), "inputBackgroundImage": img]
  guard let filter = CIFilter(name: "CISourceInCompositing", withInputParameters: parameters),
            outputImage = filter.outputImage else { return image }
  return UIImage(CGImage: context.createCGImage(outputImage, fromRect: img.extent),
                 scale: image.scale,
                 orientation: image.imageOrientation)
}

private func invertImage(image: UIImage) -> UIImage {
  guard let img = CIImage(image: image) else { return image }
  let context = CIContext(options: nil)
  let parameters = ["inputImage": img]
  guard let filter = CIFilter(name: "CIColorInvert", withInputParameters: parameters),
            outputImage = filter.outputImage else { return image }
  return UIImage(CGImage: context.createCGImage(outputImage, fromRect: img.extent),
                scale: image.scale,
                orientation: image.imageOrientation)
}

private func imageByAddingBackgroundColor(image: UIImage, color: UIColor) -> UIImage {
  guard let img = CIImage(image: image) else { return image }
  let context = CIContext(options: nil)
  let parameters = ["inputBackgroundImage": CIImage(color: CIColor(color: color)), "inputImage": img]
  guard let filter = CIFilter(name: "CISourceAtopCompositing", withInputParameters: parameters),
            outputImage = filter.outputImage else { return image }
  return UIImage(CGImage: context.createCGImage(outputImage, fromRect: img.extent),
                 scale: image.scale,
                 orientation: image.imageOrientation)
}

private func imageMaskToAlpha(image: UIImage) -> UIImage {
  guard let img = CIImage(image: image) else { return image }
  let context = CIContext(options: nil)
  let parameters = ["inputImage": img]
  guard let filter = CIFilter(name: "CIMaskToAlpha", withInputParameters: parameters),
            outputImage = filter.outputImage else { return image }
  return UIImage(CGImage: context.createCGImage(outputImage, fromRect: img.extent),
                scale: image.scale,
                orientation: image.imageOrientation)
}

public extension UIImage {
  public func heightScaledToWidth(width: CGFloat) -> CGFloat {
    let (w, h) = size.unpack
    let ratio = Ratio(w, h)
    return ratio.denominatorForNumerator(width)
  }

  public func imageWithBackgroundColor(color: UIColor) -> UIImage { return imageByAddingBackgroundColor(self, color: color) }
  public func imageWithColor(color: UIColor) -> UIImage { return imageFromImage(self, color: color) }
  public var inverted: UIImage { return invertImage(self) }
  public var maskToAlpha: UIImage { return imageMaskToAlpha(self) }
}
