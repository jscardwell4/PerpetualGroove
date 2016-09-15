//
//  SecondaryControllerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

protocol SecondaryControllerContent: class {
//  var anyAction: (() -> Void)? { get }
//  var cancelAction: (() -> Void)? { get }
//  var confirmAction: (() -> Void)? { get }
  var nextAction: (() -> Void)? { get }
  var previousAction: (() -> Void)? { get }
  var viewController: UIViewController { get }
  var supportedActions: SecondaryControllerContainer.SupportedActions { get }
  var disabledActions: SecondaryControllerContainer.SupportedActions { get }
}

extension SecondaryControllerContent {
  var supportedActions: SecondaryControllerContainer.SupportedActions { return .None }
  var disabledActions: SecondaryControllerContainer.SupportedActions { return .None }

//  var anyAction: (() -> Void)? { return nil }
//  var cancelAction: (() -> Void)? { return nil }
//  var confirmAction: (() -> Void)? { return nil }
  var nextAction: (() -> Void)? { return nil }
  var previousAction: (() -> Void)? { return nil }
}

extension SecondaryControllerContent where Self:UIViewController {
  var viewController: UIViewController { return self }
}

protocol SecondaryControllerContentDelegate {
  var secondaryContent: SecondaryControllerContent { get }
  func didShowContent(_ content: SecondaryControllerContent)
  func didHideContent(_ content: SecondaryControllerContent,
                      dismissalAction: SecondaryControllerContainer.DismissalAction)
}

extension SecondaryControllerContentDelegate {
  func didShowContent(_ content: SecondaryControllerContent) {}
  func didHideContent(_ content: SecondaryControllerContent,
                      dismissalAction: SecondaryControllerContainer.DismissalAction) {}
}

class SecondaryControllerContainer: UIViewController {

  typealias ContentDelegate = SecondaryControllerContentDelegate
  typealias Content = SecondaryControllerContent

  var primaryController: UIViewController? { return childViewControllers.first }

  fileprivate(set) var secondaryContentDelegate: ContentDelegate?
  fileprivate(set) var secondaryContent: Content?

  fileprivate(set) weak var secondaryController: SecondaryContent? {
    didSet {
      guard let controller = secondaryController else { return }

      // Hide or reveal the buttons according to the controller's settings
      cancelButton?.isHidden = controller.supportedActions ∌ .Cancel
      confirmButton?.isHidden = controller.supportedActions ∌ .Confirm

      leftArrow?.isHidden = controller.supportedActions ∌ .Previous
      rightArrow?.isHidden = controller.supportedActions ∌ .Next

      cancelButton?.isEnabled = controller.disabledActions ∌ .Cancel
      confirmButton?.isEnabled = controller.disabledActions ∌ .Confirm

      leftArrow?.isEnabled = controller.disabledActions ∌ .Previous
      rightArrow?.isEnabled = controller.disabledActions ∌ .Next

      // Add the controller's view to the blur view content
      let controllerView = controller.view!
      controllerView.frame = view.bounds.insetBy(dx: 20, dy: 20)
      controllerView.translatesAutoresizingMaskIntoConstraints = false
      controllerView.backgroundColor = nil

      blurView.contentView.insertSubview(controllerView, at: 0)
      blurView.contentView.constrain(𝗩|--20--controllerView--20--|𝗩, 𝗛|--20--controllerView--20--|𝗛)
      blurView.frame = blurFrame
    }

  }

  @IBOutlet fileprivate weak var containerView: UIView!

  var blurFrame: CGRect { guard isViewLoaded else { return .zero }; return view.bounds }

  fileprivate lazy var blurView: UIVisualEffectView = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    blurView.isUserInteractionEnabled = true

    let cancelButton = ImageButtonView(autolayout: true)
    cancelButton.image = UIImage(named: "cancel")
    cancelButton.normalTintColor = .pearlBush
    cancelButton.highlightedTintColor = .mahogany
    cancelButton.identifier = "ConfirmButton"
    cancelButton.accessibilityIdentifier = cancelButton.identifier
    cancelButton.addTarget(self,
                           action: #selector(SecondaryControllerContainer.cancel),
                           for: .touchUpInside)
    blurView.contentView.addSubview(cancelButton)
    blurView.contentView.constrain(𝗩|--cancelButton, 𝗛|--cancelButton)
    self.cancelButton = cancelButton

    let confirmButton = ImageButtonView(autolayout: true)
    confirmButton.image = UIImage(named: "confirm")
    confirmButton.normalTintColor = .pearlBush
    confirmButton.highlightedTintColor = .mahogany
    confirmButton.identifier = "ConfirmButton"
    confirmButton.accessibilityIdentifier = confirmButton.identifier
    confirmButton.addTarget(self,
                            action: #selector(SecondaryControllerContainer.confirm),
                            for: .touchUpInside)
    blurView.contentView.addSubview(confirmButton)
    blurView.contentView.constrain(𝗩|--confirmButton, confirmButton--|𝗛)
    self.confirmButton = confirmButton

    let leftArrow = ImageButtonView(autolayout: true)
    leftArrow.image = UIImage(named: "left_arrow")
    leftArrow.normalTintColor = .pearlBush
    leftArrow.highlightedTintColor = .mahogany
    leftArrow.identifier = "PreviousButton"
    leftArrow.accessibilityIdentifier = leftArrow.identifier
    leftArrow.addTarget(self,
                        action: #selector(SecondaryControllerContainer.previous),
                        for: .touchUpInside)
    blurView.contentView.addSubview(leftArrow)
    blurView.contentView.constrain(leftArrow--|𝗩, 𝗛|--leftArrow)
    self.leftArrow = leftArrow

    let rightArrow = ImageButtonView(autolayout: true)
    rightArrow.image = UIImage(named: "right_arrow")
    rightArrow.normalTintColor = .pearlBush
    rightArrow.highlightedTintColor = .mahogany
    rightArrow.identifier = "NextButton"
    rightArrow.accessibilityIdentifier = rightArrow.identifier
    rightArrow.addTarget(self,
                         action: #selector(getter: SecondaryControllerContainer.next),
                         for: .touchUpInside)
    blurView.contentView.addSubview(rightArrow)
    blurView.contentView.constrain(rightArrow--|𝗩, rightArrow--|𝗛)
    self.rightArrow = rightArrow

    return blurView
  }()

  fileprivate weak var confirmButton: ImageButtonView?
  fileprivate weak var cancelButton: ImageButtonView?

  weak var leftArrow: ImageButtonView?
  weak var rightArrow: ImageButtonView?

  /** confirm */
  @objc fileprivate func confirm() { dismissSecondaryController(.confirm) }

  /** cancel */
  @objc fileprivate func cancel() { dismissSecondaryController(.cancel) }

  /** next */
  @objc fileprivate func next() { nextAction?() }

  /** previous */
  @objc fileprivate func previous() { previousAction?() }

//  var anyAction: (() -> Void)?      { return secondaryController?.anyAction      }
//  var cancelAction: (() -> Void)?   { return secondaryController?.cancelAction   }
//  var confirmAction: (() -> Void)?  { return secondaryController?.confirmAction  }
  var nextAction: (() -> Void)?     { return secondaryController?.nextAction     }
  var previousAction: (() -> Void)? { return secondaryController?.previousAction }

  /** refreshNavigationArrows */
  func refreshNavigationArrows() {

  }

  @objc enum DismissalAction: Int { case none, cancel, confirm }

  func presentContentForDelegate(_ delegate: SecondaryControllerContentDelegate,
                       completion: ((Bool) -> Void)? = nil)
  {
//    guard secondaryController == nil else { return }
    secondaryContentDelegate = delegate
    secondaryContent = delegate.secondaryContent

    let controller = secondaryContent!.viewController
    addChildViewController(controller)
//    secondaryController = controller


    let options: UIViewAnimationOptions = [.allowAnimatedContent]

    let animations = {
      [view = view, blurView = blurView] in
      view?.addSubview(blurView)
      view?.constrain(
        𝗩|--blurView.frame.y--blurView--((view?.bounds.maxY)! - blurView.frame.maxY)--|𝗩,
        𝗛|--blurView.frame.x--blurView--((view?.bounds.maxX)! - blurView.frame.maxX)--|𝗛
      )
    }

    UIView.transition(with: view, duration: 0.25, options: options, animations: animations) {
      [unowned self] completed in
      controller.didMove(toParentViewController: self)
      completion?(completed)
    }

  }

  /**
   presentSecondaryController:completion:

   - parameter controller: SecondaryContent
   - parameter completion: ((Bool) -> Void
  */
//  func presentSecondaryController(controller: SecondaryContent,
//                       completion: ((Bool) -> Void)? = nil)
//  {
//    guard secondaryController == nil else { return }
//
//    addChildViewController(controller)
//    secondaryController = controller
//
//
//    let options: UIViewAnimationOptions = [.AllowAnimatedContent]
//
//    let animations = {
//      [view = view, blurView = blurView] in
//      view.addSubview(blurView)
//      view.constrain(
//        𝗩|--blurView.frame.y--blurView--(view.bounds.maxY - blurView.frame.maxY)--|𝗩,
//        𝗛|--blurView.frame.x--blurView--(view.bounds.maxX - blurView.frame.maxX)--|𝗛
//      )
//    }
//
//    UIView.transitionWithView(view, duration: 0.25, options: options, animations: animations) {
//      [unowned self] completed in
//      controller.didMoveToParentViewController(self)
//      completion?(completed)
//    }
//
//  }

  func completionForDismissalAction(_ dismissalAction: DismissalAction) -> (Bool) -> Void {
    return {
      [weak self] completed in
      guard completed,
        let delegate = self?.secondaryContentDelegate, let content = self?.secondaryContent else { return }

      delegate.didHideContent(content, dismissalAction: dismissalAction)
//      switch dismissalAction {
//        case .Cancel:  self?.cancelAction?()
//        case .Confirm: self?.confirmAction?()
//        case .None:    break
//      }
    }
  }

  /** dismissSecondaryController */
  func dismissSecondaryController(_ dismissalAction: DismissalAction = .none) {
    guard let controller = secondaryController else { return }

    controller.willMove(toParentViewController: nil)
    controller.removeFromParentViewController()

    let options: UIViewAnimationOptions = [.allowAnimatedContent]

    let animations = {
      [weak blurView = blurView, weak controllerView = controller.view] in
      controllerView?.removeFromSuperview()
      blurView?.removeFromSuperview()
    }
    let completion = completionForDismissalAction(dismissalAction)

    UIView.transition(with: view,
                              duration: 0.25,
                              options: options,
                              animations: animations,
                              completion: completion)
  }

}

extension SecondaryControllerContainer {
  struct SupportedActions: OptionSet {
    let rawValue: Int
    static let None     = SupportedActions(rawValue: 0b0000)
    static let Cancel   = SupportedActions(rawValue: 0b0001)
    static let Confirm  = SupportedActions(rawValue: 0b0010)
    static let Previous = SupportedActions(rawValue: 0b0100)
    static let Next     = SupportedActions(rawValue: 0b1000)
  }
}
