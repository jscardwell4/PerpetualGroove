//
//  FormField.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/4/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class FormField: NSObject {

  weak var _control: UIView?

  public let name: String

  public init(name n: String) { name = n; super.init() }

  /** The internally used control of the field */
  var control: UIView { fatalError("the FormField class is abstract, `control` must be overridden by a subclass") }

  /** Whether the field's `control` should be editable */
  public var editable = true { didSet { _control?.userInteractionEnabled = editable } }

  // MARK: - Customizing a field's appearance
  public var font: UIFont?
  public var selectedFont: UIFont?
  public var color: UIColor?
  public var selectedColor: UIColor?

  // MARK: - Managing the type and value of a field
  public var value: Any?
  public var valid: Bool { return true }
  public var changeHandler: ((FormField) -> Void)?

}
