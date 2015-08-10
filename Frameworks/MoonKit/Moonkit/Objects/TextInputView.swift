//
//  TextInputView.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/5/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class TextInputView: UIInputView {

  var insertText: ((String) -> Bool)!
  var deleteBackward: ((Void) -> Bool)!
  var done: ((Void) -> Bool)!

  let target: UITextInput!

  var currentText: String {
    get {
      let range = target.textRangeFromPosition(target.beginningOfDocument, toPosition: target.endOfDocument)
      return target.textInRange(range!)!
    }
    set {
      let range = target.textRangeFromPosition(target.beginningOfDocument, toPosition: target.endOfDocument)
      target.replaceRange(range!, withText: newValue)
    }
  }

  /**
  initWithFrame:target:

  - parameter frame: CGRect
  - parameter target: UIResponder
  */
  public required init(frame: CGRect, target: UITextInput) {
    self.target = target
    super.init(frame: frame, inputViewStyle: .Keyboard)

    if let field = target as? UITextField {

      insertText = {
        (text: String) -> Bool in
        if let selectedTextRange = field.selectedTextRange {
          let location = field.offsetFromPosition(field.beginningOfDocument, toPosition: selectedTextRange.start)
          let length = field.offsetFromPosition(selectedTextRange.start, toPosition: selectedTextRange.end)
          let range = NSRange(location: location, length: length)
          if field.delegate?.textField?(field, shouldChangeCharactersInRange: range, replacementString: text) != false {
            field.insertText(text)
            return true
          }
        }
        return false
      }

      done = {
        () -> Bool in
        return field.resignFirstResponder()
      }

      deleteBackward = {
        () -> Bool in

        if let selectedTextRange = field.selectedTextRange {
          let location = field.offsetFromPosition(field.beginningOfDocument, toPosition: selectedTextRange.start)
          let length = field.offsetFromPosition(selectedTextRange.start, toPosition: selectedTextRange.end)
          var range = NSRange(location: location, length: length)
          if range.length == 0 { range.location -= 1; range.length = 1 }
          if field.delegate?.textField?(field, shouldChangeCharactersInRange: range, replacementString: "") != false {
            field.deleteBackward()
            return true
          }
        }
        return false
      }

    } else if let view = target as? UITextView {

      insertText = {
        (text: String) -> Bool in

        if let selectedTextRange = view.selectedTextRange {
          let location = view.offsetFromPosition(view.beginningOfDocument, toPosition: selectedTextRange.start)
          let length = view.offsetFromPosition(selectedTextRange.start, toPosition: selectedTextRange.end)
          let range = NSRange(location: location, length: length)
          if view.delegate?.textView?(view, shouldChangeTextInRange: range, replacementText: text) != false {
            view.insertText(text)
            return true
          }
        }
        return false
      }

      done = {
        () -> Bool in

        return view.resignFirstResponder()
      }

      deleteBackward = {
        () -> Bool in

        if let selectedTextRange = view.selectedTextRange {
          let location = view.offsetFromPosition(view.beginningOfDocument, toPosition: selectedTextRange.start)
          let length = view.offsetFromPosition(selectedTextRange.start, toPosition: selectedTextRange.end)
          var range = NSRange(location: location, length: length)
          if range.length == 0 { range.location -= 1; range.length = 1 }
          if view.delegate?.textView?(view, shouldChangeTextInRange: range, replacementText: "") != false {
            view.deleteBackward()
            return true
          }
        }
        return false
      }

    }



  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { target = nil; super.init(coder: aDecoder) }

}
