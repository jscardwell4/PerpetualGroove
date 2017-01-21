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

/// Protocol for classes to produce content for an instance of `SecondaryControllerContainer`.
protocol SecondaryContent: class {

  typealias SupportedActions = SecondaryControllerContainer.SupportedActions

  /// Action invoked by touching the right arrow, when visible. Default is `nil`.
  var nextAction: (() -> Void)? { get }

  /// Action invoked by touching the left arrow, when visible. Default is `nil`.
  var previousAction: (() -> Void)? { get }

  /// The view controller displaying the content to present. Defaults to `self` if `self is UIViewController`.
  var viewController: UIViewController { get }

  /// Which of the available actions should be displayed. Default is `none`.
  var supportedActions: SupportedActions { get set }

  /// Which of the displayed actions should be disabled. Default is `none`.
  var disabledActions: SupportedActions { get set }

}

extension SecondaryContent {

  var supportedActions: SupportedActions { get { return .none } set {} }
  var disabledActions: SupportedActions { get { return .none } set {} }

  var nextAction: (() -> Void)? { return nil }
  var previousAction: (() -> Void)? { return nil }

}

extension SecondaryContent where Self:UIViewController {

  var viewController: UIViewController { return self }

}

/// Protocol for types that want to provide content for an instance `SecondaryControllerContainer`.
protocol SecondaryContentProvider {

  typealias DismissalAction = SecondaryControllerContainer.DismissalAction

  /// The content from which the view controller to present shall be obtained.
  var secondaryContent: SecondaryContent { get }

  /// Whether the controller returned by `secondaryContent.viewController` is currently visible.
  var isShowingContent: Bool { get }

  /// Callback invoked by an instance of `SecondaryControllerContainer` when the controller returned by
  /// `secondaryContent.viewController` is presented.
  func didShow(content: SecondaryContent)

  /// Callback invoked by an instance of `SecondaryControllerContainer` when the controller returned by
  /// `secondaryContent.viewController` is dismissed.
  func didHide(content: SecondaryContent, dismissalAction: DismissalAction)

}

/// Abstract base class that subclasses `UIViewController` to provide an infrastructure for managing the
/// display of secondary content via child view controllers.
class SecondaryControllerContainer: UIViewController {

  /// The view controller responsible for managing the primary content for the container's view.
  var primaryController: UIViewController? { return childViewControllers.first }

  /// The view controller responsible for managing the secondary content for the container's view.
  var secondaryController: UIViewController? { return content?.viewController }

  /// The object providing `content`.
  private(set) var contentProvider: SecondaryContentProvider?

  /// The object producing `secondaryController`.
  private(set) var content: SecondaryContent?

  /// View within which child view controller content shall appear.
  @IBOutlet private weak var containerView: UIView!

  /// The frame used to position `blurView`.
  var blurFrame: CGRect { guard isViewLoaded else { return .zero }; return view.bounds }

  /// The visual effect view containing any the secondary content.
  private lazy var blurView: UIVisualEffectView = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    blurView.constrain(𝗛∶|[blurView.contentView]|, 𝗩∶|[blurView.contentView]|)
    blurView.isUserInteractionEnabled = true
    blurView.frame = self.blurFrame

    // Helper for configuring a new button.
    func button(image: UIImage, identifier: String, action: Selector) -> ImageButtonView {
      let button = ImageButtonView(autolayout: true)
      button.image = image
      button.normalTintColor = .pearlBush
      button.highlightedTintColor = .mahogany
      button.identifier = identifier
      button.accessibilityIdentifier = identifier
      button.addTarget(self, action: action, for: .touchUpInside)
      return button
    }

    let cancelButton = button(image: #imageLiteral(resourceName: "cancel"),
                              identifier: "ConfirmButton",
                              action: #selector(SecondaryControllerContainer.cancel))
    blurView.contentView.addSubview(cancelButton)
    blurView.contentView.constrain(𝗩∶|-[cancelButton, ==44], 𝗛∶|-[cancelButton, ==44])
    self.cancelButton = cancelButton

    let confirmButton = button(image: #imageLiteral(resourceName: "confirm"),
                               identifier: "ConfirmButton",
                               action: #selector(SecondaryControllerContainer.confirm))
    blurView.contentView.addSubview(confirmButton)
    blurView.contentView.constrain(𝗩∶|-[confirmButton, ==cancelButton], 𝗛∶[confirmButton, ==cancelButton]-|)
    self.confirmButton = confirmButton

    let leftArrow = button(image: #imageLiteral(resourceName: "left_arrow"),
                           identifier: "PreviousButton",
                           action: #selector(SecondaryControllerContainer.previous))
    blurView.contentView.addSubview(leftArrow)
    blurView.contentView.constrain(𝗩∶[leftArrow, ==cancelButton]-|, 𝗛∶|-[leftArrow, ==cancelButton])
    self.leftArrow = leftArrow

    let rightArrow = button(image: #imageLiteral(resourceName: "right_arrow"),
                            identifier: "NextButton",
                            action: #selector(getter: SecondaryControllerContainer.next))
    blurView.contentView.addSubview(rightArrow)
    blurView.contentView.constrain(𝗩∶[rightArrow, ==cancelButton]-|, 𝗛∶[rightArrow, ==cancelButton]-|)
    self.rightArrow = rightArrow

    return blurView
  }()

  /// Button displayed by `blurView` that invokes `confirm()`.
  fileprivate weak var confirmButton: ImageButtonView?

  /// Button displayed by `blurView` that invokes `cancel()`.
  fileprivate weak var cancelButton: ImageButtonView?

  /// Button displayed by `blurView` that invokes `previous()`.
  weak var leftArrow: ImageButtonView?

  /// Button displayed by `blurView` that invokes `next()`.
  weak var rightArrow: ImageButtonView?

  /// Dismisses secondary content and invokes completion with `.confirm`.
  @objc private func confirm() { dismiss(completion: completion(forAction: .confirm)) }

  /// Dismisses secondary content and invokes completion with `.cancel`.
  @objc private func cancel() { dismiss(completion: completion(forAction: .cancel)) }

  /// Invokes `content.nextAction()`.
  @objc private func next() { content?.nextAction?() }

  /// Invokes `content.previousAction()`
  @objc private func previous() { content?.previousAction?() }

  /// Enumeration of the possible actions associated with secondary content dismissal.
  @objc enum DismissalAction: Int { case none, cancel, confirm }

  /// Presents the secondary content provided by `provider` by embedding in `blurView`.
  func presentContent(for provider: SecondaryContentProvider,
                      completion: ((Bool) -> Void)? = nil)
  {
    contentProvider = provider
    content = provider.secondaryContent

    let viewController = content!.viewController
    addChildViewController(viewController)

    guard let childView = viewController.view else {
      fatalError("Failed to get view from secondary content controller.")
    }

    childView.translatesAutoresizingMaskIntoConstraints = false
    blurView.contentView.addSubview(childView)

    blurView.contentView.constrain(𝗩∶[cancelButton!]-[childView]-[leftArrow!],
                                   𝗛∶|-[childView]-|)

    let options: UIViewAnimationOptions = [.allowAnimatedContent]

    let animations = {
      [view = view, blurView = blurView] in
      guard let view = view else { return }
      view.addSubview(blurView)
      view.constrain(
        𝗩∶|-blurView.frame.y-[blurView]-(view.bounds.maxY - blurView.frame.maxY)-|,
        𝗛∶|-blurView.frame.x-[blurView]-(view.bounds.maxX - blurView.frame.maxX)-|
      )
    }

    UIView.transition(with: view, duration: 0.25, options: options, animations: animations) {
      [unowned self] completed in

      self.secondaryController?.didMove(toParentViewController: self)
      completion?(completed)
    }

  }

  /// Returns a completion block appropriate for `action`.
  func completion(forAction action: DismissalAction) -> (Bool) -> Void {
    return {
      [weak self] completed in

      guard completed else { return }
      self?.contentProvider?.didHide(content: (self?.content!)!, dismissalAction: action)
    }
  }

  /// Removes `blurView` and the secondary content it displays.
  func dismiss(completion: @escaping (Bool) -> Void) {
    guard let controller = secondaryController else { return }

    controller.willMove(toParentViewController: nil)
    controller.removeFromParentViewController()

    let options: UIViewAnimationOptions = [.allowAnimatedContent]

    let animations = {
      [weak blurView = blurView, weak controllerView = controller.view] in
      controllerView?.removeFromSuperview()
      blurView?.removeFromSuperview()
    }

    UIView.transition(with: view,
                      duration: 0.25,
                      options: options,
                      animations: animations,
                      completion: completion)
  }

  /// Structure for specifying a set of actions with corrsponding buttons displayable by `blurView`.
  struct SupportedActions: OptionSet {
    let rawValue: Int

    static let none     = SupportedActions(rawValue: 0b0000)
    static let cancel   = SupportedActions(rawValue: 0b0001)
    static let confirm  = SupportedActions(rawValue: 0b0010)
    static let previous = SupportedActions(rawValue: 0b0100)
    static let next     = SupportedActions(rawValue: 0b1000)
  }

}
