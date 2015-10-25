import Foundation
import UIKit
import MoonKit
class A {}

struct _Weak<T:AnyObject> {
  private(set) weak var reference: T?
  init(_ ref: T) {
    weak var r = ref
    reference = r
  }
}

var a: A? = A()

var weakA = _Weak(a!)

weakA.reference

a = nil

weakA.reference
a

class B {}

class __Weak<T:AnyObject> {
  private var _value: (() -> T?)?
  var value: T? { return _value?() }
  init(_ v: T?) {
    _value = {[weak v] in v }
  }
}

var b: B? = B()

var weakB = __Weak(b)

weakB.value

b = nil

weakB.value
