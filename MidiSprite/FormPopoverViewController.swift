//
//  FormPopoverViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/5/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

class FormPopoverViewController: UIViewController {

  /** loadView */
  override func loadView() {
    view = IntrinsicSizeDelegatingView(autolayout: true) {
      [unowned self] _ in CGSize(width: min(UIScreen.mainScreen().bounds.width - 10, 365),
                                 height: self.formView.intrinsicContentSize().height)
    }
    view.setContentHuggingPriority(1000, forAxis: .Horizontal)
    view.setContentHuggingPriority(1000, forAxis: .Vertical)
    view.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
    view.setContentCompressionResistancePriority(1000, forAxis: .Vertical)
    view.backgroundColor = .popoverBackgroundColor
    view.opaque = true

    let formView = FormView(form: form)
    formView.labelFont            = .labelFont
    formView.labelTextColor       = .labelTextColor
    formView.controlFont          = .controlFont
    formView.controlColor         = .controlColor
    formView.controlSelectedFont  = .controlSelectedFont
    formView.controlSelectedColor = .controlSelectedColor
    formView.tintColor            = .tintColor
    formView.backgroundColor      = .popoverBackgroundColor
    formView.opaque = true
    view.addSubview(formView)
    self.formView = formView
    view.setNeedsUpdateConstraints()
    
  }

  private weak var formView: FormView!

  var form: Form { return Form(fields: []) }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()
    let id = Identifier(self, "ViewWidth")
    guard view.constraintsWithIdentifier(id).count == 0 else { return }
    view.constrain([𝗩|formView|𝗩, 𝗛|formView|𝗛] --> id)
  }

}
