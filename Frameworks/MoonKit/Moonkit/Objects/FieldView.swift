//
//  FieldView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/11/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

/** View subclass for a single form field with a name label and a control for capturing the value */
final class FieldView: UIView {

  // MARK: - Field-related properties

  let field: FormField

  // MARK: - Customizing appearance

  var labelFont: UIFont? {
    get { return label?.font }
    set { if let font = newValue { label?.font = font } }
  }

  var labelTextColor: UIColor? {
    get { return label?.textColor }
    set { if let color = newValue { label?.textColor = color } }
  }

  var controlFont: UIFont? {
    get { return field.font }
    set { guard let font = newValue else { return }; field.font = font }
  }

  var controlColor: UIColor? {
    get { return field.color }
    set { guard let color = newValue else { return }; field.color = color }
  }

  var controlSelectedFont: UIFont? {
    get { return field.selectedFont }
    set { guard let font = newValue else { return }; field.selectedFont = font }
  }

  var controlSelectedColor: UIColor? {
    get { return field.selectedColor }
    set { guard let color = newValue else { return }; field.selectedColor = color }
  }

  /** Overridden to return the field view's `name` property */
  override var nametag: String! { get { return field.name } set {} }

  // MARK: - Initializing the view

  /** initializeIVARs */
  private func initializeIVARs() {
    translatesAutoresizingMaskIntoConstraints = false
    let label = UILabel(autolayout: true)
    label.text = field.name
    label.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)
    label.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
    label.nametag = "name"
    addSubview(label)
    self.label = label
    let control = field.control
    addSubview(control)
    self.control = control
  }

  /**
  Initialize the view with a name and field

  - oarameter t: Int
  - parameter n: String
  - parameter f: Field
  */
  init(tag t: Int, field f: FormField) {
    field = f
    super.init(frame: CGRect.zero)
    tag = t
    initializeIVARs()
  }

  private weak var label: UILabel?
  private weak var control: UIView?

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - Constraints

  /**
  requiresConstraintBasedLayout

  - returns: Bool
  */
  override class func requiresConstraintBasedLayout() -> Bool { return true }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override func intrinsicContentSize() -> CGSize {
    if let label = label, control = control {
      let lSize = label.intrinsicContentSize()
      let cSize = control.intrinsicContentSize()
      return CGSize(width: lSize.width + 10.0 + cSize.width, height: max(lSize.height, cSize.height))
    } else { return CGSize(square: UIViewNoIntrinsicMetric) }
  }

  /** updateConstraints */
  override func updateConstraints() {
    super.updateConstraints()
    let id = Identifier(self, "Internal")
    if constraintsWithIdentifier(id).count == 0, let label = label, control = control {
      constrain(𝗩|label|𝗩 --> id, 𝗩|control|𝗩 --> id)
      constrain(𝗛|label --> id, control.left => label.right + 10.0 --> id, control|𝗛 --> id)
    }
  }

}
