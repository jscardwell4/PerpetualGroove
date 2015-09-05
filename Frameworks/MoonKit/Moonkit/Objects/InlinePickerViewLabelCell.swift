//
//  InlinePickerViewLabelCell.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/11/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

final class InlinePickerViewLabelCell: InlinePickerViewCell {

  private let label = UILabel(autolayout: true)

  var text: NSAttributedString? { didSet { if !selected { label.attributedText = text } } }

  var selectedText: NSAttributedString? { didSet { if selected { label.attributedText = selectedText } } }

  override var selected: Bool {
    didSet {
      switch selected {
      case true where selectedText != nil: label.attributedText = selectedText
      default: label.attributedText = text
      }
    }
  }

  /** initializeIVARs */
  override func initializeIVARs() {
    super.initializeIVARs()

    label.adjustsFontSizeToFitWidth = true
    label.numberOfLines = 1
    label.lineBreakMode = .ByTruncatingTail
    label.attributedText = selected ? selectedText : text
    contentView.addSubview(label)

    #if TARGET_INTERFACE_BUILDER
      autoresizesSubviews = false
      contentMode = .Redraw
      label.contentMode = .Redraw
//      clearsContextBeforeDrawing = false
//      label.clearsContextBeforeDrawing = false
//      contentView.clearsContextBeforeDrawing = false
      contentView.contentMode = .Redraw
      opaque = false
      label.opaque = false
      contentView.opaque = false
    #endif
  }

  /**
  encodeWithCoder:

  - parameter aCoder: NSCoder
  */
  override func encodeWithCoder(aCoder: NSCoder) {
    super.encodeWithCoder(aCoder)
    if let keyedCoder = aCoder as? NSKeyedArchiver {
      keyedCoder.encodeObject(text, forKey: "InlinePickerViewCellText")
      keyedCoder.encodeObject(selectedText, forKey: "InlinePickerViewCellSelectedText")
    }
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame) }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    text = aDecoder.decodeObjectForKey("InlinePickerViewCellText") as? NSAttributedString
    selectedText = aDecoder.decodeObjectForKey("InlinePickerViewCellSelectedText") as? NSAttributedString
  }

  override var description: String {
    var result = String(super.description.characters.dropLast())
    result.appendContentsOf("; text = " + (text != nil ? "'\(text!.string)'" : "nil") + ">")
    return result
  }

  /** updateConstraints */
  override func updateConstraints() {
    super.updateConstraints()
    constrain(𝗛|label|𝗛, 𝗩|label|𝗩)
  }

}