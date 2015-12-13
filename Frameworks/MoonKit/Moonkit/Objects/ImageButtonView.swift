//
//  ImageButtonView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

@IBDesignable
public class ImageButtonView: ToggleControl {

  override public var tintColor: UIColor! { didSet { setNeedsDisplay() } }

  public enum ImageState: String, Equatable, Hashable { case Default, Highlighted, Disabled, Selected }

  // MARK: - Images

  @IBInspectable public var image: UIImage? { 
    didSet { 
      if let image = image where image.renderingMode != .AlwaysTemplate {
        self.image = image.imageWithRenderingMode(.AlwaysTemplate)
      }
      refresh() 
    } 
  }
  @IBInspectable public var highlightedImage: UIImage? { 
    didSet { 
      if let highlightedImage = highlightedImage where highlightedImage.renderingMode != .AlwaysTemplate {
        self.highlightedImage = highlightedImage.imageWithRenderingMode(.AlwaysTemplate)
      }
      refresh() 
    } 
  }
  @IBInspectable public var disabledImage: UIImage? { 
    didSet { 
      if let disabledImage = disabledImage where disabledImage.renderingMode != .AlwaysTemplate {
        self.disabledImage = disabledImage.imageWithRenderingMode(.AlwaysTemplate)
      }
      refresh() 
    } 
  }
  @IBInspectable public var selectedImage: UIImage? { 
    didSet { 
      if let selectedImage = selectedImage where selectedImage.renderingMode != .AlwaysTemplate {
        self.selectedImage = selectedImage.imageWithRenderingMode(.AlwaysTemplate)
      }
      refresh() 
    } 
  }

  /**
  imageForState:

  - parameter state: ImageState

  - returns: UIImage?
  */
  public func imageForState(state: ImageState) -> UIImage? {
    switch state {
      case .Default: return image
      case .Highlighted: return highlightedImage
      case .Disabled: return disabledImage
      case .Selected: return selectedImage
    }
  }

  /**
  setImage:forState:

  - parameter image: UIImage?
  - parameter forState: ImageState
  */
  public func setImage(image: UIImage?, forState state: ImageState) {
    switch state {
        case .Default: self.image = image
        case .Highlighted: highlightedImage = image
        case .Disabled: disabledImage = image
        case .Selected: selectedImage = image
    }
  }

  private weak var _currentImage: UIImage? { didSet { if _currentImage != oldValue { setNeedsDisplay() } } }
  public var currentImage: UIImage? { return _currentImage ?? image }

  /**
  imageForState:

  - parameter state: UIControlState

  - returns: UIImage?
  */
  private func imageForState(state: UIControlState) -> UIImage? {
    let img: UIImage?
    switch state {
      case [.Disabled] where disabledImage != nil:                  img = disabledImage!
      case [.Selected] where selectedImage != nil:                  img = selectedImage!
      case [.Highlighted] where highlightedImage != nil:            img = highlightedImage!
      case [.Disabled], [.Selected], [.Highlighted]:                img = currentImage
      default:                                                      img = image
    }
    return img
  }


  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override public func intrinsicContentSize() -> CGSize { return image?.size ?? CGSize(square: UIViewNoIntrinsicMetric) }

  /** refresh */
  public override func refresh() { super.refresh(); _currentImage = imageForState(state) }

  /** setup */
  private func setup() { opaque = false }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  public override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    aCoder.encodeBool(toggle,             forKey: "toggle")
    aCoder.encodeObject(image,            forKey: "image")
    aCoder.encodeObject(selectedImage,    forKey: "selectedImage")
    aCoder.encodeObject(highlightedImage, forKey: "highlightedImage")
    aCoder.encodeObject(disabledImage,    forKey: "disabledImage")
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { 
    super.init(coder: aDecoder); setup() 
    image            = aDecoder.decodeObjectForKey("image")            as? UIImage
    selectedImage    = aDecoder.decodeObjectForKey("selectedImage")    as? UIImage
    highlightedImage = aDecoder.decodeObjectForKey("highlightedImage") as? UIImage
    disabledImage    = aDecoder.decodeObjectForKey("disabledImage")    as? UIImage
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    guard let image = _currentImage else { return }

    let context = UIGraphicsGetCurrentContext()
    CGContextSaveGState(context)
    CGContextClearRect(context, rect)
    UIRectClip(rect)

    let 𝝙size = image.size - rect.size
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat

    switch contentMode {
      case .ScaleToFill, .Redraw:
        (x, y, w, h) = rect.unpack4
      case .ScaleAspectFit:
        (w, h) = image.size.aspectMappedToSize(rect.size, binding: true).unpack
        x = rect.midX - half(w)
        y = rect.midY - half(h)
      case .ScaleAspectFill:
        (w, h) = image.size.aspectMappedToSize(rect.size, binding: false).unpack
        x = rect.midX - half(w)
        y = rect.midY - half(h)
      case .Center:
        x = rect.x - half(𝝙size.width)
        y = rect.y - half(𝝙size.height)
        (w, h) = image.size.unpack
      case .Top:
        x = rect.x - half(𝝙size.width)
        y = rect.y
        (w, h) = image.size.unpack
      case .Bottom:
        x = rect.x - half(𝝙size.width)
        y = rect.maxY - image.size.height
        (w, h) = image.size.unpack
      case .Left:
        x = rect.x
        y = rect.y - half(𝝙size.height)
        (w, h) = image.size.unpack
      case .Right:
        x = rect.maxX - image.size.width
        y = rect.y - half(𝝙size.height)
        (w, h) = image.size.unpack
      case .TopLeft:
        (x, y) = rect.origin.unpack
        (w, h) = image.size.unpack
      case .TopRight:
        x = rect.maxX - image.size.width
        y = rect.y
        (w, h) = image.size.unpack
      case .BottomLeft:
        x = rect.x
        y = rect.maxY - image.size.height
        (w, h) = image.size.unpack
      case .BottomRight:
        x = rect.maxX - image.size.width
        y = rect.maxY - image.size.height
        (w, h) = image.size.unpack
    }

    image.drawInRect(CGRect(x: x, y: y, width: w, height: h))

    tintColor.setFill()
    UIBezierPath(rect: rect).fillWithBlendMode(.SourceIn, alpha: 1)

    CGContextRestoreGState(context)
  }
}
