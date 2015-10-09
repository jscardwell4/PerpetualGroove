//
//  Marquee.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/7/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable public class Marquee: UIView {

  private let textLayer: CALayer = {
    let layer = CALayer()
    layer.contentsScale = UIScreen.mainScreen().scale
    return layer
  }()

  private var staleCache = true { didSet { guard staleCache else { return }; setNeedsLayout() } }

  @IBInspectable public var text: String = "" {
    didSet {
      guard text != oldValue else { return }
      textStorage.mutableString.setString(text)
      staleCache = true
      invalidateIntrinsicContentSize()
    }
  }

  private var 𝝙w: CGFloat = 0

  /** updateTextLayer */
  private func updateTextLayer() {
    guard staleCache else { return }
    defer { staleCache = false; scrollCheck() }

    // Set the text container with the view's height and unlimited width
    textContainer.size = CGSize(width: CGFloat.max, height: bounds.height)

    // Get the glyph range and the bounding rect for laying out all the glyphs
    let characterRange = NSRange(0 ..< text.utf16.count)
    let glyphRange = layoutManager.glyphRangeForCharacterRange(characterRange, actualCharacterRange: nil)
    layoutManager.ensureLayoutForGlyphRange(glyphRange)

    let textRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
    𝝙w = max(textRect.width - bounds.width, 0)

    // Adjust the result according to how it fits the view's bounds
    var textFrame = textRect
    textFrame.origin.y += half(bounds.height) - half(font.pointSize)

    let extendText: Bool

    switch bounds.contains(textRect) {
      case true:  textFrame.origin.x += half(bounds.width - textRect.width); extendText = false
      case false: textFrame.size.width = textRect.width * 2;                 extendText = true
    }

    // Update the text layer's frame
    textLayer.frame = textFrame.integral

    // Ensure there is an appropriate size and content or exit
    guard !(textLayer.bounds.isEmpty || textStorage.string.isEmpty) else { textLayer.contents = nil; return }

    // Draw the text into a bitmap context
    UIGraphicsBeginImageContextWithOptions(textLayer.bounds.size, false, 0)

    layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: .zero)

    // If we made the layer twice as wide, draw the text again
    if extendText {
      let separator = NSAttributedString(string: scrollSeparator,
                                         attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
      separator.drawAtPoint(CGPoint(x: textRect.width, y: 0))
      let wʹ = separator.size().width
      𝝙w += wʹ
      layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: CGPoint(x: textRect.width + wʹ, y: 0))
    }

    guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
      fatalError("Failed to generate image for text layer")
    }

    UIGraphicsEndImageContext()

    // Update the layer's contents
    textLayer.contents = image.CGImage
  }

  @IBInspectable public var scrollSeparator: String = "•"
  @IBInspectable public var textColor: UIColor = .blackColor() {
    didSet {
      textStorage.beginEditing()
      textStorage.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(0 ..< textStorage.length))
      textStorage.endEditing()
      staleCache = true
    }
  }
  public var font: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline) {
    didSet {
      textStorage.beginEditing()
      textStorage.addAttribute(NSFontAttributeName, value: font, range: NSRange(0 ..< textStorage.length))
      textStorage.endEditing()
      staleCache = true
      invalidateIntrinsicContentSize()
    }
  }

  @IBInspectable public var fontName: String {
    get { return font.fontName }
    set { if let font = UIFont(name: newValue, size: font.pointSize) { self.font = font } }
  }

  @IBInspectable public var fontSize: CGFloat {
    get { return font.pointSize }
    set { font = font.fontWithSize(newValue) }
  }

  /** How fast to scroll text in characters per second */
  @IBInspectable public var scrollSpeed: CFTimeInterval = 1

  /** Whether the text should scroll when it does not all fit */
  @IBInspectable public var scrollEnabled: Bool = true { didSet { scrollCheck() } }

  private var isScrolling = false

  private static let AnimationKey = "MarqueeScroll"

  /** scrollCheck */
  private func scrollCheck() {
    switch (scrollEnabled, isScrolling) {
      case (true, false) where shouldScroll: beginScrolling()
      case (false, true) where isScrolling: endScrolling()
      default: break
    }
  }

  private var shouldScroll: Bool {
    guard scrollEnabled && window != nil else { return false }
    return textLayer.bounds.width > bounds.width
  }

  public let layoutManager: NSLayoutManager = NSLayoutManager()
  public let textStorage: NSTextStorage = NSTextStorage()
  public let textContainer: NSTextContainer = {
    let container = NSTextContainer()
    container.lineBreakMode = .ByCharWrapping
    container.lineFragmentPadding = 0
    container.maximumNumberOfLines = 1
    return container
    }()

  /** setup */
  private func setup() {
    layoutManager.usesFontLeading = false
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)
    textStorage.beginEditing()
    textStorage.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: 0))
    textStorage.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(location: 0, length: 0))
    textStorage.endEditing()
    layer.addSublayer(textLayer)
    layer.masksToBounds = true
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  /** layoutSubviews */
  public override func layoutSubviews() { super.layoutSubviews(); updateTextLayer() }

  public override var frame: CGRect {
    didSet {
      guard frame.size != oldValue.size else { return }
      staleCache = true
    }
  }

  public override var bounds: CGRect {
    didSet {
      guard bounds.size != oldValue.size else { return }
      staleCache = true
    }
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize { return textLayer.bounds.size }

  /** didMoveToWindow */
  public override func didMoveToWindow() { super.didMoveToWindow(); guard window != nil else { return }; scrollCheck() }

  /** beginScrolling */
  private func beginScrolling() {
    guard scrollEnabled && !isScrolling else { return }

    let point = CGPoint(x: bounds.width, y: bounds.midY)
    let characterIndex = layoutManager.characterIndexForPoint(point, inTextContainer: textContainer)
    let excess = text.utf16.count - (characterIndex + 1)

    guard excess > 0 else { logWarning("There are not any excess characters to scroll into view"); return }

    let animation = CABasicAnimation(keyPath: "transform.translation.x")
    animation.duration = scrollSpeed * CFTimeInterval(text.utf16.count + scrollSeparator.utf16.count)
    animation.toValue = -bounds.width - 𝝙w
    animation.delegate = self
    animation.repeatCount = Float.infinity
    textLayer.addAnimation(animation, forKey: Marquee.AnimationKey)
  }

  /**
  animationDidStart:

  - parameter anim: CAAnimation
  */
  public override func animationDidStart(anim: CAAnimation) { isScrolling = true }

  /**
  animationDidStop:finished:

  - parameter anim: CAAnimation
  - parameter flag: Bool
  */
  public override func animationDidStop(anim: CAAnimation, finished flag: Bool) { isScrolling = false }

  /** endScrolling */
  private func endScrolling() { guard isScrolling else { return }; textLayer.removeAnimationForKey(Marquee.AnimationKey) }

}
