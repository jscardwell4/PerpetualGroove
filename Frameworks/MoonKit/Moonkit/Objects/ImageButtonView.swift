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
    image.drawInRect(rect)

    tintColor.setFill()
    UIBezierPath(rect: rect).fillWithBlendMode(.SourceIn, alpha: 1)

    CGContextRestoreGState(context)
  }
}
