//
//  IntegerInputView.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/10/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class IntegerInputView: TextInputView {

  /**
  initWithFrame:target:

  - parameter frame: CGRect
  - parameter target: UIResponder
  */
  public required init(frame: CGRect, target: UITextInput) {
    super.init(frame: frame, target: target)

   let index = [
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
      "|[one][two(==one)][three(==one)]|",
      "|[four(==one)][five(==one)][six(==one)]|",
      "|[seven(==one)][eight(==one)][nine(==one)]|",
      "|[erase(==one)][zero(==one)][done(==one)]|",
      "V:|[one(==one)][four(==one)][seven(==one)][erase(==one)]|",
      "V:|[two(==one)][five(==one)][eight(==one)][zero(==one)]|",
      "V:|[three(==one)][six(==one)][nine(==one)][done(==one)]|"
    )

    constrain(format, views: views)

  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

}
