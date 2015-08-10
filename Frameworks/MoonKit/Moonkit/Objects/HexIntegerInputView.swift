//
//  HexIntegerInputView.swift
//  MSKit
//
//  Created by Jason Cardwell on 12/5/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class HexIntegerInputView: TextInputView {

  /**
  initWithFrame:target:

  - parameter frame: CGRect
  - parameter target: UIResponder
  */
  public required init(frame: CGRect, target: UITextInput) {
    super.init(frame: frame, target: target)

    let index = [
      "a": "A",      "b": "B",     "c": "C",
      "d": "D",      "e": "E",     "f": "F",
      "one": "1",    "two": "2",   "three": "3",
      "four": "4",   "five": "5",  "six": "6",
      "seven": "7",  "eight": "8", "nine": "9",
      "erase": "⌫", "zero": "0",  "done": "Done"
    ]
    
    var views: [String: KeyInputButton] = [:]

    for (name, value) in index {

      let b = KeyInputButton(autolayout: true)
      b.title = value

      switch name {

        case "erase":
          b.style = .DeleteBackward
          b.addActionBlock({[unowned self] in _ = self.deleteBackward()}, forControlEvents: UIControlEvents.TouchUpInside)

        case "done":
          b.style = .Done
          b.addActionBlock({[unowned self] in _ = self.done()}, forControlEvents: UIControlEvents.TouchUpInside)

        default:
          b.addActionBlock({[unowned self] in _ = self.insertText(value)}, forControlEvents: UIControlEvents.TouchUpInside)
      }

      addSubview(b)
      views[name] = b

    }

    let format = "\n".join(
      "|[a][b(==a)][c(==a)]|",
      "|[d(==a)][e(==a)][f(==a)]|",
      "|[one(==a)][two(==a)][three(==a)]|",
      "|[four(==a)][five(==a)][six(==a)]|",
      "|[seven(==a)][eight(==a)][nine(==a)]|",
      "|[erase(==a)][zero(==a)][done(==a)]|",
      "V:|[a][d(==a)][one(==a)][four(==a)][seven(==a)][erase(==a)]|",
      "V:|[b(==a)][e(==a)][two(==a)][five(==a)][eight(==a)][zero(==a)]|",
      "V:|[c(==a)][f(==a)][three(==a)][six(==a)][nine(==a)][done(==a)]|"
    )

    constrain(format, views: views)

  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

}
