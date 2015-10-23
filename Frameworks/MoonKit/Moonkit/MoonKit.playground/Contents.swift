import Foundation
import UIKit
import MoonKit

class A {}

class B: A {}

func downcastArray<T, U>(sequence: [U]) -> [T]? {
  var result: [T] = []
  for u in sequence {
    if let ut = u as? T {
      result.append(ut)
    }
  }

  return result.count == sequence.count ? result : nil
}

let bs = [B]()
let a: [A] = downcastArray(bs)!

protocol P {}

struct C: P {}

let cs = [C]()
let p: [P] = downcastArray(cs)!