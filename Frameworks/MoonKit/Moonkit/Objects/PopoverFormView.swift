//
//  PopoverFormView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/9/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit

public class PopoverFormView: PopoverView {

  let form: Form

  public private(set) weak var formView: FormView!

  /**
  initWithLabelData:dismissal:

  - parameter labelData: [LabelData]
  - parameter callback: ((PopoverView) -> Void
  */
  public init(form f: Form, dismissal callback: ((PopoverView) -> Void)?) {
    form = f
    super.init(dismissal: callback)
  }

  /**
  Initialization with coder is unsupported

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  /** initializeIVARs */
  override func initializeIVARs() {
    super.initializeIVARs()
    let formView = FormView(form: form)
    contentView.addSubview(formView)
    self.formView = formView
  }

  override public func updateConstraints() {
    super.updateConstraints()

    let id = Identifier(self, "Internal")

    guard constraintsWithIdentifier(id).count == 0, let parent = superview else { return }

    constrain([formView.width ≤ (parent.bounds.width - 20), formView.height ≤ (parent.bounds.height - 20)] --> id)
    constrain([𝗩|formView|𝗩, 𝗛|formView|𝗛] --> id)
  }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override public func intrinsicContentSize() -> CGSize { return formView.intrinsicContentSize() }
}
