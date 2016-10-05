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

  typealias SupportedActions = SecondaryControllerContainer.SupportedActions

  var nextAction: (() -> Void)? { get }
  var previousAction: (() -> Void)? { get }

  var viewController: UIViewController { get }

  var supportedActions: SupportedActions { get set }
  var disabledActions: SupportedActions { get set }

}

extension SecondaryControllerContent {

  var supportedActions: SupportedActions { get { return .None } set {} }
  var disabledActions: SupportedActions { get { return .None } set {} }

  var nextAction: (() -> Void)? { return nil }
  var previousAction: (() -> Void)? { return nil }

}

extension SecondaryControllerContent where Self:UIViewController {
  var viewController: UIViewController { return self }
}

protocol SecondaryControllerContentProvider {

  var secondaryContent: SecondaryControllerContent { get }
  var isShowingContent: Bool { get }

  func didShow(content: SecondaryControllerContent)
  func didHide(content: SecondaryControllerContent,
               dismissalAction: SecondaryControllerContainer.DismissalAction)

}

class SecondaryControllerContainer: UIViewController {

  var primaryController: UIViewController? { return childViewControllers.first }
  var secondaryController: UIViewController? { return content?.viewController }

  private(set) var contentProvider: SecondaryControllerContentProvider?
  private(set) var content: SecondaryControllerContent?

  @IBOutlet private weak var containerView: UIView!

  var blurFrame: CGRect { guard isViewLoaded else { return .zero }; return view.bounds }

  private lazy var blurView: UIVisualEffectView = {
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    blurView.isUserInteractionEnabled = true

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
    blurView.contentView.constrain(𝗩|--cancelButton, 𝗛|--cancelButton)
    self.cancelButton = cancelButton

    let confirmButton = button(image: #imageLiteral(resourceName: "confirm"),
                               identifier: "ConfirmButton",
                               action: #selector(SecondaryControllerContainer.confirm))
    blurView.contentView.addSubview(confirmButton)
    blurView.contentView.constrain(𝗩|--confirmButton, confirmButton--|𝗛)
    self.confirmButton = confirmButton

    let leftArrow = button(image: #imageLiteral(resourceName: "left_arrow"),
                           identifier: "PreviousButton",
                           action: #selector(SecondaryControllerContainer.previous))
    blurView.contentView.addSubview(leftArrow)
    blurView.contentView.constrain(leftArrow--|𝗩, 𝗛|--leftArrow)
    self.leftArrow = leftArrow

    let rightArrow = button(image: #imageLiteral(resourceName: "right_arrow"),
                            identifier: "NextButton",
                            action: #selector(getter: SecondaryControllerContainer.next))
    blurView.contentView.addSubview(rightArrow)
    blurView.contentView.constrain(rightArrow--|𝗩, rightArrow--|𝗛)
    self.rightArrow = rightArrow

    return blurView
  }()

  fileprivate weak var confirmButton: ImageButtonView?
  fileprivate weak var cancelButton: ImageButtonView?

  weak var leftArrow: ImageButtonView?
  weak var rightArrow: ImageButtonView?

  @objc private func confirm() { dismiss(completion: completion(forAction: .confirm)) }
  @objc private func cancel() { dismiss(completion: completion(forAction: .cancel)) }

  @objc private func next() { content?.nextAction?() }
  @objc private func previous() { content?.previousAction?() }

  @objc enum DismissalAction: Int { case none, cancel, confirm }

  func presentContent(for provider: SecondaryControllerContentProvider,
                      completion: ((Bool) -> Void)? = nil)
  {
    contentProvider = provider
    content = provider.secondaryContent

    addChildViewController(content!.viewController)


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

      self.secondaryController?.didMove(toParentViewController: self)
      completion?(completed)
    }

  }

  func completion(forAction action: DismissalAction) -> (Bool) -> Void {
    return {
      [weak self] completed in

      guard completed else { return }
      self?.contentProvider?.didHide(content: (self?.content!)!, dismissalAction: action)
    }
  }

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
