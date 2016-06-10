//: Playground - noun: a place where people can play

import UIKit
import MoonKit

class Tokenizer {

  init(string: String) { scanner = NSScanner(string: string) }

  private var scanner: NSScanner

  private var location: Int { get { return scanner.scanLocation } set { scanner.scanLocation = newValue } }

  struct Token {
    let value: String
    let action: () -> Void
  }

  var tokens: [Token] = []


}