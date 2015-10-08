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

  @IBInspectable public var text: String = "" {
    didSet {
      guard text != oldValue else { return }
      layer.removeAllAnimations()
      textStorage.mutableString.setString(text)
      offset = 0
      if shouldScroll { beginScrolling() }
    }
  }
  @IBInspectable public var scrollSeparator: String = "•"
  @IBInspectable public var textColor: UIColor = .blackColor() {
    didSet {
      textStorage.beginEditing()
      textStorage.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(location: 0, length: textStorage.length))
      textStorage.endEditing()
    }
  }
  public var font: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline) {
    didSet {
      textStorage.beginEditing()
      textStorage.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: textStorage.length))
      textStorage.endEditing()
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

  @IBInspectable public var scrollSpeed: NSTimeInterval = 0.5
  @IBInspectable public var scrollEnabled: Bool = true {
    didSet {
      contentMode = scrollEnabled ? .Redraw : .ScaleToFill
      if shouldScroll { beginScrolling() } else if isScrolling { endScrolling() }
    }
  }

  private var isScrolling = false

  private var shouldScroll: Bool {
    guard scrollEnabled && window != nil else { return false }
    let glyphRange = layoutManager.glyphRangeForBoundingRect(bounds, inTextContainer: textContainer)
    let characterRange = layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
    return text.utf16.count > characterRange.length
}

  public let layoutManager: NSLayoutManager = NSLayoutManager()
  public let textStorage: NSTextStorage = NSTextStorage()
  public let textContainer: NSTextContainer = {
      let container = NSTextContainer()
      container.lineBreakMode = .ByCharWrapping
      return container
    }()

  /** setup */
  private func setup() {
    textContainer.size = bounds.size
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)
    textStorage.beginEditing()
    textStorage.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: 0))
    textStorage.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(location: 0, length: 0))
    textStorage.endEditing()
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


  /** didChangeSize */
  private func didChangeSize() {
    textContainer.size = bounds.size
    if shouldScroll { beginScrolling() } else if isScrolling { endScrolling() }
  }

  public override var bounds: CGRect { didSet { guard bounds.size != oldValue.size else { return }; didChangeSize() } }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    return (text as NSString).sizeWithAttributes([NSFontAttributeName: font, NSForegroundColorAttributeName: textColor])
  }

  var offset = 0 {
    didSet {
      offset %= text.utf16.count
      guard offset != oldValue else { return }

      let 𝝙 = textStorage.length - text.utf16.count
      textStorage.beginEditing()

      switch offset {
        case 0 where 𝝙 == 0:
          textStorage.mutableString.setString(text)
        case 0 where 𝝙 > 0:
          textStorage.mutableString.setString("\(text)\(scrollSeparator)")
        default:
          let head = text[text.startIndex.advancedBy(offset) ..< text.endIndex]
          let tail = text[text.startIndex ..< text.startIndex.advancedBy(offset)]
          textStorage.mutableString.setString("\(head)\(scrollSeparator)\(tail)")
      }

      textStorage.endEditing()
      setNeedsDisplay()
    }
  }

  /** beginScrolling */
  private func beginScrolling() {
    guard scrollEnabled && !isScrolling else { return }
    isScrolling = true
    setNeedsDisplay()
  }

  /** endScrolling */
  private func endScrolling() {
    guard isScrolling else { return }
    guard offset > 0 else { isScrolling = false; return }
    isScrolling = false
    offset = 0
  }

  /**
  drawRect:

  - parameter rect: CGRect
  */
  public override func drawRect(rect: CGRect) {
    guard textStorage.length > 0 else { return }
    let glyphRange = layoutManager.glyphRangeForBoundingRect(rect, inTextContainer: textContainer)
    let textRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
    let point = rect.origin + (rect.center - textRect.center)
    layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: point)
    if isScrolling {
      delayedDispatchToMain(scrollSpeed) { [weak self] in self?.offset++ }
    }
  }

}
