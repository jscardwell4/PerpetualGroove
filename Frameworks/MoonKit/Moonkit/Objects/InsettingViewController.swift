//
//  InsettingViewController.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/29/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit

public class InsettingViewController: UIViewController {

  public var selfSizing = false { didSet { view.setNeedsUpdateConstraints() } }

  public var minInset: CGFloat = 4 { didSet { minInset = max(4, minInset) } }

  public var insets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20) {
    didSet {
      insets.top = max(insets.top, minInset)
      insets.left = max(insets.left, minInset)
      insets.bottom = max(insets.bottom, minInset)
      insets.right = max(insets.right, minInset)

      top?.constant = insets.top
      left?.constant = insets.left
      bottom?.constant = insets.bottom
      right?.constant = insets.right
    }
  }

  public var childViewController: UIViewController? {
    didSet {

      let removeChild: (UIViewController) -> Void = {
        [unowned self] in

        $0.willMoveToParentViewController(nil)
        $0.removeFromParentViewController()
        self.childView?.removeFromSuperview()
      }

      let addChild: (UIViewController) -> Void = {
        [unowned self] in

        self.addChildViewController($0)
        if self.isViewLoaded() { self.childView = $0.view }
      }

      switch (oldValue, childViewController) {
        case let (nil, child?):
          addChild(child)
        case let (old?, nil):
          removeChild(old)
        case let (old?, child?) where old != child:
          transitionFromViewController(old,
                      toViewController: child,
                              duration: 0.25,
                               options: [],
                            animations: { addChild(child) },
                            completion: { _ in removeChild(old) })

        default: break
      }
    }
  }

  /** updateViewConstraints */
  public override func updateViewConstraints() {
    super.updateViewConstraints()

    var id = Identifier(self, "Effect")

    if view.constraintsWithIdentifier(id).count == 0, let effectView = effectView {
      view.constrain([𝗛|effectView|𝗛, 𝗩|effectView|𝗩, 𝗛|effectView.contentView|𝗛, 𝗩|effectView.contentView|𝗩, ] --> id)
    }

    id = Identifier(self, "Content")

    if view.constraintsWithIdentifier(id).count == 0, let contentView = contentView {
      view.constrain([𝗩|contentView|𝗩, 𝗛|contentView|𝗛] --> id)
    }

    id = Identifier(self, "ChildView")

    if view.constraintsWithIdentifier(id).count == 0, let childView = childViewController?.view, contentView = contentView  {
      view.constrain([
        childView.centerX => contentView.centerX,
        childView.centerY => contentView.centerY,
//        childView.left => contentView.left,
//        childView.right => contentView.right,
//        childView.top => contentView.top,
//        childView.bottom => contentView.bottom
        ] --> id)


    }

    if insetConstraints == nil, let contentView = contentView {
      top = (contentView.top => view.top - insets.top).constraint
      left = (contentView.left => view.left - insets.left).constraint
      bottom = (contentView.bottom => view.bottom - insets.bottom).constraint
      right = (contentView.right => view.right - insets.right).constraint
    }


    if let insetConstraints = insetConstraints { insetConstraints.apply {[active = !selfSizing] in $0.active = active } }

  }


  /** init */
  public init() { super.init(nibName: nil, bundle: nil) }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

  public weak var contentView: UIView?

  private weak var childView: UIView? {
    didSet {
      guard isViewLoaded(),  let childView = childView, contentView = contentView else { return }
      childView.nametag = "childView"
      contentView.addSubview(childView)
      childView.translatesAutoresizingMaskIntoConstraints = false
      view.setNeedsUpdateConstraints()
    }
  }
  private weak var effectView: UIVisualEffectView?
  private weak var snapshotView: UIView?
  private weak var background: UIView?

  private weak var right:  NSLayoutConstraint?
  private weak var left:   NSLayoutConstraint?
  private weak var top:    NSLayoutConstraint?
  private weak var bottom: NSLayoutConstraint?

  private var insetConstraints: [NSLayoutConstraint]? {
    guard let top = top, left = left, bottom = bottom, right = right else { return nil }
    return [top, left, bottom, right]
  }
  

  /** loadView */
  public override func loadView() {
    view = UIView(frame: UIScreen.mainScreen().bounds)
    view.nametag = "view"

    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    effectView.translatesAutoresizingMaskIntoConstraints = false
    effectView.nametag = "effectView"

    let effectViewContent = effectView.contentView
    effectViewContent.translatesAutoresizingMaskIntoConstraints = false
    effectViewContent.nametag = "effectViewContent"

    view.addSubview(effectView)
    self.effectView = effectView

    let contentView = UIView(autolayout: true)
    contentView.nametag = "contentView"
    effectView.contentView.addSubview(contentView)
    self.contentView = contentView

    childView = childViewController?.view

    view.setNeedsUpdateConstraints()

  }
  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  public override func viewWillAppear(animated: Bool) {
    super.viewWillDisappear(animated)

    guard let effectView = effectView, window = view.window else { return }

    self.snapshotView?.removeFromSuperview()

    let snapshotView: UIView
    if isBeingPresented(), let controller = presentingViewController where controller.isViewLoaded() {
      snapshotView = controller.view.snapshotViewAfterScreenUpdates(false)
    } else {
      snapshotView = window.snapshotViewAfterScreenUpdates(false)
    }

    view.insertSubview(snapshotView, belowSubview: effectView)
    self.snapshotView = snapshotView
  }

  /** cancelAction */
  func cancelAction() { MSLogDebug("") }

  /** submitAction */
  func submitAction() { MSLogDebug("") }


}
