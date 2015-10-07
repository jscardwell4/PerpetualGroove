import Foundation
import UIKit
import CoreText
import MoonKit

let string = "I am a string, bitches!!!"

extension _NSRange: CustomStringConvertible {
  public var description: String { return "_NSRange { location: \(location); length: \(length) }" }
}

final class Marquee: UIView {

  var text: String = "" {
    didSet { textStorage.beginEditing(); textStorage.mutableString.setString(text); textStorage.endEditing() }
  }
  var textColor: UIColor = .blackColor() {
    didSet {
      textStorage.beginEditing()
      textStorage.addAttribute(NSForegroundColorAttributeName, value: textColor, range: NSRange(location: 0, length: textStorage.length))
      textStorage.endEditing()
    }
  }
  var font: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline) {
    didSet {
      textStorage.beginEditing()
      textStorage.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0, length: textStorage.length))
      textStorage.endEditing()
    }
  }

  private let layoutManager: NSLayoutManager = NSLayoutManager()
  private let textStorage: NSTextStorage = NSTextStorage()
  private let textContainer: NSTextContainer = { let container = NSTextContainer(); container.lineBreakMode = .ByCharWrapping; return container }()

  /** setup */
  private func setup() {
    layoutManager.delegate = self
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
  override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }


  override var bounds: CGRect { didSet { textContainer.size = bounds.size } }

  var offset = 0 {
    didSet {
      offset = (0 ... textStorage.length - 1).clampValue(offset)
      guard offset != oldValue else { return }
      guard text.utf16.count == textStorage.length else { fatalError("wtf") }
      let head = text[text.startIndex.advancedBy(offset) ..< text.endIndex]
      let tail = text[text.startIndex ..< text.startIndex.advancedBy(offset)]
      textStorage.beginEditing()
      let string = textStorage.mutableString
      string.setString("\(head)\(tail)")
      textStorage.endEditing()
    }
  }

  override func drawRect(rect: CGRect) {
    dump(textContainer)
    guard textStorage.length > 0 else { return }
    var effectiveRange = NSRange()
    guard layoutManager.textContainerForGlyphAtIndex(offset, effectiveRange: &effectiveRange) == textContainer else { fatalError() }
    dump(effectiveRange)
//    let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
//    dump(glyphRange)
    layoutManager.drawGlyphsForGlyphRange(effectiveRange, atPoint: rect.origin)
  }

}

extension Marquee: NSLayoutManagerDelegate {

  /**
  layoutManager:shouldGenerateGlyphs:properties:characterIndexes:font:forGlyphRange:

  - parameter layoutManager: NSLayoutManager
  - parameter glyphs: UnsafePointer<CGGlyph>
  - parameter props: UnsafePointer<NSGlyphProperty>
  - parameter charIndexes: UnsafePointer<Int>
  - parameter aFont: UIFont
  - parameter glyphRange: NSRange

  - returns: Int
  */
  func layoutManager(layoutManager: NSLayoutManager,
shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
          properties props: UnsafePointer<NSGlyphProperty>,
    characterIndexes charIndexes: UnsafePointer<Int>,
                font aFont: UIFont,
       forGlyphRange glyphRange: NSRange) -> Int
  {
    print("layoutManager:shouldGenerateGlyphs:properties:characterIndexes:font:forGlyphRange:")
    dump(layoutManager)
    dump(glyphs)
    dump(props)
    dump(charIndexes)
    dump(aFont)
    dump(glyphRange)
    print("\n")
    return 0
  }

  /**
  layoutManagerDidInvalidateLayout:

  - parameter sender: NSLayoutManager
  */
  func layoutManagerDidInvalidateLayout(sender: NSLayoutManager) {
    print("layoutManagerDidInvalidateLayout:")
    dump(sender)
    print("\n")
    setNeedsDisplay()
  }
}

let marquee = Marquee(frame: CGRect(size: CGSize(width: 100, height: 20)))
marquee.backgroundColor = .lightGrayColor()
marquee.textColor = .purpleColor()
marquee.text = string
marquee.offset = 1
marquee.offset = 2

marquee.offset = 3

marquee.offset = 4

marquee.offset = 5

marquee.offset = 6

marquee.offset = 7

marquee.offset = 8

marquee.offset = 9

marquee.offset = 10
