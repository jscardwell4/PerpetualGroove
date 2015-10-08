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

  /** updateTextLayer */
  private func updateTextLayer() {
    guard staleCache else { return }
    defer { staleCache = false; scrollCheck() }

    textContainer.size = CGSize(width: CGFloat.max, height: bounds.height)
    let glyphRange = layoutManager.glyphRangeForCharacterRange(NSRange(0 ..< text.utf16.count), actualCharacterRange: nil)
    layoutManager.ensureLayoutForGlyphRange(glyphRange)
    let (textOrigin, textSize) = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer).unpack2
    textLayer.frame = CGRect(origin: CGPoint(x: textOrigin.x, y: half(bounds.height) - half(font.pointSize)), size: textSize)

    guard !(textLayer.bounds.isEmpty || textStorage.string.isEmpty) else { textLayer.contents = nil; return }

    UIGraphicsBeginImageContextWithOptions(textLayer.bounds.size, false, 0)
    layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: textOrigin)
    guard let image = UIGraphicsGetImageFromCurrentImageContext() else { fatalError("Failed to generate image for text layer") }
    UIGraphicsEndImageContext()
    textLayer.contents = image.CGImage

    scrollCheck()
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

  @IBInspectable public var scrollSpeed: NSTimeInterval = 5
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
    let characterIndex = layoutManager.characterIndexForPoint(CGPoint(x: bounds.width, y: bounds.midY),
                                              inTextContainer: textContainer,
                     fractionOfDistanceBetweenInsertionPoints: nil)
    let excess = text.utf16.count - (characterIndex + 1)
    guard excess > 0 else {
      logWarning("There are not any excess characters to scroll into view")
      return
    }

    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    animation.duration = scrollSpeed * CFTimeInterval(excess)
    animation.keyTimes = [NSNumber(double: 0), NSNumber(double: 0.5), NSNumber(double: 1)]
    animation.values = [NSNumber(double: 0), NSNumber(double: Double(bounds.width - textLayer.bounds.width)), NSNumber(double: 0)]
    animation.delegate = self
    logDebug("adding animation: \(animation)\n       to layer: \(textLayer)")
    textLayer.addAnimation(animation, forKey: Marquee.AnimationKey)
  }

  /**
  animationDidStart:

  - parameter anim: CAAnimation
  */
  public override func animationDidStart(anim: CAAnimation) {
    isScrolling = true
  }

  /**
  animationDidStop:finished:

  - parameter anim: CAAnimation
  - parameter flag: Bool
  */
  public override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
    isScrolling = false
    guard flag else { return }
    scrollCheck()
  }

  /** endScrolling */
  private func endScrolling() {
    guard isScrolling else { return }
    textLayer.removeAnimationForKey(Marquee.AnimationKey)
  }

}
