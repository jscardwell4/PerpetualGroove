import Foundation
import UIKit
import CoreText
import MoonKit
import Eveleth
import Chameleon

extension _NSRange: CustomStringConvertible {
  public var description: String { return "_NSRange { location: \(location); length: \(length) }" }
}

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

  @IBInspectable public var scrollSpeed: NSTimeInterval = 0.5
  @IBInspectable public var scrollEnabled: Bool = false { didSet { scrollCheck() } }

  private var isScrolling = false

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

  var offset = 0 {
    didSet {
      offset %= text.utf16.count
      guard offset != oldValue else { return }

//      let 𝝙 = textStorage.length - text.utf16.count
//      textStorage.beginEditing()
//
//      switch offset {
//        case 0 where 𝝙 == 0:
//          textStorage.mutableString.setString(text)
//        case 0 where 𝝙 > 0:
//          textStorage.mutableString.setString("\(text)\(scrollSeparator)")
//        default:
//          let head = text[text.startIndex.advancedBy(offset) ..< text.endIndex]
//          let tail = text[text.startIndex ..< text.startIndex.advancedBy(offset)]
//          textStorage.mutableString.setString("\(head)\(scrollSeparator)\(tail)")
//      }
//
//      textStorage.endEditing()
//      setNeedsDisplay()
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

}

let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
container.backgroundColor = .darkGrayColor()
let marquee = Marquee(frame: CGRect(x: 70, y: 10, width: 60, height: 40))
marquee.backgroundColor = rgb(51, 50, 49)
marquee.text = "Pop Brass"
marquee.textColor = Chameleon.kelleyPearlBush
marquee.font = Eveleth.thinFontWithSize(12)
//marquee.setNeedsDisplay()
container.addSubview(marquee)
marquee.textLayer.setAffineTransform(CGAffineTransform(tx: marquee.bounds.width - marquee.textLayer.bounds.width, ty: 0))
container
