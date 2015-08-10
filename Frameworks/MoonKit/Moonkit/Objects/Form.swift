//
//  Form.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/4/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

public final class Form: NSObject {

  public typealias ChangeHandler = (Form, FormField) -> Void

  public var fields: [FormField]
  public var changeHandler: ChangeHandler?

  /**
  initWithTemplates:

  - parameter templates: OrderedDictionary<String, FieldTemplate>
  - parameter handler: ChangeHandler? = nil
  */
  public init(fields f: [FormField], changeHandler handler: ChangeHandler? = nil) {
    fields = f
    super.init()
    changeHandler = handler
    f.forEach {(field: FormField) in field.changeHandler = self.didChangeField }
  }

  /**
  didChangeField:

  - parameter field: Field
  */
  func didChangeField(field: FormField) { changeHandler?(self, field) }

  /**
  nameForField:

  - parameter field: Field

  - returns: String?
  */
//  func nameForField(field: Field) -> String? {
//    if let idx = fields.values.indexOf(field) { return fields.keys[idx] } else { return nil }
//  }

  public var invalidFields: [(Int, FormField)] {
    var result: [(Int, FormField)] = []
    for (idx, field) in fields.enumerate() where !field.valid { result.append((idx, field)) }
    return result
  }

  public var valid: Bool { return invalidFields.count == 0 }

//  public var values: [Any?] {
//    var values: [Any?] = []
//    for (_, n, f) in fields { if f.valid, let value: Any = f.value { values[n] = value } else { return nil } }
//    return values
//  }

  public override var description: String {
    return "Form: {\n\t" + "\n\t".join(fields.map {(field: FormField) in "\(field.name) = \(String(field.value))"}) + "\n}"
  }

}

