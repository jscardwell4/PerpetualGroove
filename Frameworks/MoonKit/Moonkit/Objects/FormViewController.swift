//
//  FormViewController.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/9/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

public class FormViewController: UIViewController {

  public typealias Submission = (Form) -> Void
  public typealias Cancellation = () -> Void

  // MARK: - Initializating the controller

  /**
  Default initializer takes the form and cancel/submit callbacks

  - parameter form: Form
  - parameter submit: Submission? = nil
  - parameter cancel: Cancellation? = nil
  */
  public init(form f: Form, didSubmit submit: Submission? = nil, didCancel cancel: Cancellation? = nil) {
    form = f; didSubmit = submit; didCancel = cancel
    super.init(nibName: nil, bundle: nil)
    modalTransitionStyle = .CrossDissolve
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  public let form: Form

  // MARK: - The controller's private properties
  private let didSubmit: Submission?
  private let didCancel: Cancellation?

  private weak var snapshotView: UIView?
  private weak var effectView: UIVisualEffectView?
  public private(set) weak var formView: FormView?
  private weak var toolbar: UIToolbar?

  // MARK: - Loading/updating the controller's view

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  public override func prefersStatusBarHidden() -> Bool { return true }

  /** loadView */
  public override func loadView() {
    view = UIView(frame: UIScreen.mainScreen().bounds)
    view.nametag = "view"

    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    effectView.translatesAutoresizingMaskIntoConstraints = false
    effectView.nametag = "effectView"
    view.addSubview(effectView)
    self.effectView = effectView

    let formView = FormView(form: form, style: .Shadow)
    effectView.contentView.addSubview(formView)
    formView.nametag = "formView"
    self.formView = formView

    let toolbar = UIToolbar.newForAutolayout()
    toolbar.nametag = "toolbar"
    toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .Any, barMetrics: .Default)
    toolbar.tintColor = UIColor(white: 0.5, alpha: 1)
    toolbar.items = [UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelAction"),
                     UIBarButtonItem.flexibleSpace(),
                     UIBarButtonItem(title: "Submit", style: .Done, target: self, action: "submitAction")]
    effectView.contentView.addSubview(toolbar)
    self.toolbar = toolbar

    view.setNeedsUpdateConstraints()

  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  public override func viewWillAppear(animated: Bool) {
    if isBeingPresented(), let controller = presentingViewController where controller.isViewLoaded() {
      let snapshot = controller.view.snapshotViewAfterScreenUpdates(false)
      snapshotView?.removeFromSuperview()
      assert(effectView != nil)
      view.insertSubview(snapshot, belowSubview: effectView!)
      snapshotView = snapshot
    }
  }

  /** updateViewConstraints */
  public override func updateViewConstraints() {
    super.updateViewConstraints()
    let id = Identifier(self, "Internal")
    guard view.constraintsWithIdentifier(id).count == 0, let effect = effectView, form = formView, tool = toolbar else { return }

    view.constrain([𝗛|effect|𝗛, 𝗩|effect|𝗩] --> id)
    view.constrain([form.centerX => effect.centerX, form.centerY => effect.centerY] --> id)
    view.constrain([tool.left => form.left, tool.right => form.right, tool.top => form.bottom] --> id)
    view.constrain([
      form.left ≥ view.left + 4,
      form.right ≤ view.right - 4,
      form.top ≥ view.top + 4,
      form.bottom ≤ view.bottom - 4
    ] --> id)
  }

  // MARK: - Actions

  /** cancelAction */
  func cancelAction() { didCancel?() }

  /** submitAction */
  func submitAction() { if form.valid { didSubmit?(form) } }

}
