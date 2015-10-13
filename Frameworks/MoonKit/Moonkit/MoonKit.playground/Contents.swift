import Foundation
import UIKit
import MoonKit

protocol LogicGateInput: BooleanType {

}

struct ANDGate: BooleanType {
  var inputs: [BooleanType]
  var boolValue: Bool { guard inputs.count == 2 else { return false }; return inputs[0].boolValue && inputs[1].boolValue }
}



struct LogicGate<InputType: BooleanType>: BooleanType {
  var input: InputType
  var boolValue: Bool {
    return evaluate()
  }
  func evaluate() -> Bool {
    return true
  }
}