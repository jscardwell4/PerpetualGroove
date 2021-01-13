//
//  SecondaryControllerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 1/7/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import UIKit

// MARK: - SecondaryControllerContainer

/// Abstract base class that subclasses `UIViewController` to provide an infrastructure
/// for managing the display of secondary content via child view controllers.
open class SecondaryControllerContainer: UIViewController
{
  /// The view controller responsible for managing the primary content for the
  /// container's view.
  public var primaryController: UIViewController? { children.first }

  /// The view controller responsible for managing the secondary content for the
  /// container's view.
  public var secondaryController: UIViewController? { content?.viewController }

  /// The object providing `content`.
  public private(set) var contentProvider: SecondaryContentProvider?

  /// The object producing `secondaryController`.
  public private(set) var content: SecondaryContent?

  /// View within which child view controller content shall appear.
  @IBOutlet private var containerView: UIView!

  /// The frame used to position `blurView`.
  open var blurFrame: CGRect { isViewLoaded ? view.bounds : .zero }

  /// The visual effect view serving as a container for any secondary content being
  /// displayed. In addition to the secondary content, the blur view contains the
  /// cancel, confirm, next, and previous buttons which may or may not be visible
  /// depending on the supported actions of the secondary content provider.
  private lazy var blurView: UIVisualEffectView = {
    // Create the blur view with a dark blur.
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    // Constrain the blur view's content so that it stretches vertically and
    // horizontally with the blur view.
    blurView.constrain(𝗛∶|[blurView.contentView]|, 𝗩∶|[blurView.contentView]|)

    // Enable user interaction within the blur view.
    blurView.isUserInteractionEnabled = true

    // Set the blur view's frame to the value of the `blurFrame` property.
    blurView.frame = self.blurFrame

    /// Helper for configuring a new button. Returns a button with the specified image
    /// and identifier, a 'pearl bush' tint color, a 'mahogany' highlighted tint color,
    /// and the specified action targeting `self` on touch up inside button bounds.
    ///
    /// - Parameters:
    ///   - image: The `UIImage` to assign to the button.
    ///   - identifier: The identifier for the button.
    ///   - action: The action to assign to the button.
    /// - Returns: An `ImageButtonView` with the specified configuration.
    func button(image: UIImage, identifier: String, action: Selector) -> ImageButtonView
    {
      let button = ImageButtonView(autolayout: true)

      button.image = image
      button.normalTintColor = .quaternaryColor1
      button.highlightedTintColor = .highlightColor
      button.identifier = identifier
      button.accessibilityIdentifier = identifier
      button.addTarget(self, action: action, for: .touchUpInside)

      return button
    }

    // Create the cancel button.
    let cancelButton = button(image: #imageLiteral(resourceName: "cancel"),
                              identifier: "CancelButton",
                              action: #selector(cancel))

    // Add the cancel button to the blur view's content view.
    blurView.contentView.addSubview(cancelButton)

    // Constrain the cancel button to be the standard distance from the top and left
    // with a height and width of 44.
    blurView.contentView.constrain(𝗩∶|-[cancelButton, ==44], 𝗛∶|-[cancelButton, ==44])

    // Assign the cancel button to the corresponding property.
    self.cancelButton = cancelButton

    // Create the confirm button.
    let confirmButton = button(image: #imageLiteral(resourceName: "confirm"), identifier: "ConfirmButton",
                               action: #selector(confirm))

    // Add the confirm button to the blur view's content view.
    blurView.contentView.addSubview(confirmButton)

    // Constrain the confirm button to be the standard distance from the top and
    // right with a height and width equal to the cancel button.
    blurView.contentView.constrain(𝗩∶|-[confirmButton, ==cancelButton],
                                   𝗛∶[confirmButton, ==cancelButton]-|)

    // Assign the confirm button to the corresponding property.
    self.confirmButton = confirmButton

    // Create the previous button.
    let previousButton = button(image: #imageLiteral(resourceName: "left_arrow"), identifier: "PreviousButton",
                                action: #selector(previous))

    // Add the previous button to the blur view's content view.
    blurView.contentView.addSubview(previousButton)

    // Constrain the previous button to be the standard distance from the bottom and
    // left with a height and width equal to the cancel button.
    blurView.contentView.constrain(𝗩∶[previousButton, ==cancelButton]-|,
                                   𝗛∶|-[previousButton, ==cancelButton])

    // Assign the previous button to the corresponding property.
    self.previousButton = previousButton

    // Create the next button.
    let nextButton = button(image: #imageLiteral(resourceName: "right_arrow"), identifier: "NextButton",
                            action: #selector(getter: next))

    // Add the next button to the blur view's content view.
    blurView.contentView.addSubview(nextButton)

    // Constrain the next button to be the standard distance from the bottom and right
    // with a height and width equal to the cancel button.
    blurView.contentView.constrain(𝗩∶[nextButton, ==cancelButton]-|,
                                   𝗛∶[nextButton, ==cancelButton]-|)

    // Assign the next button to the corresponding property.
    self.nextButton = nextButton

    return blurView

  }()

  /// Button displayed with the secondary content for allowing the user to confirm
  /// edits and hide the blur view that contains the secondary content.
  ///
  /// - Note: This button is hidden when the secondary content provider does not
  ///         support the `confirm` action.
  private weak var confirmButton: ImageButtonView?

  /// Button displayed with the secondary content for allowing the user to cancel
  /// edits and hide the blur view that contains the secondary content.
  ///
  /// - Note: This button is hidden when the secondary content provider does not
  ///         support the `cancel` action.
  private weak var cancelButton: ImageButtonView?

  /// Button displayed with the secondary content for allowing the user to invoke the
  /// 'previous' action provided by the secondary content provider.
  ///
  /// - Note: This button is hidden when the secondary content provider does not support
  ///         the `previous` action.
  public weak var previousButton: ImageButtonView?

  /// Button displayed with the secondary content for allowing the user to invoke
  /// the 'next' action provided by the secondary content provider.
  ///
  /// - Note: This button is hidden when the secondary content provider does not
  ///         support the `next` action.
  public weak var nextButton: ImageButtonView?

  /// Dismisses secondary content and invokes completion with `.confirm`.
  @objc private func confirm() { dismiss(completion: completion(forAction: .confirm)) }

  /// Dismisses secondary content and invokes completion with `.cancel`.
  @objc private func cancel() { dismiss(completion: completion(forAction: .cancel)) }

  /// Invokes the secondary content's 'next' action.
  @objc private func next() { content?.nextAction?() }

  /// Invokes the secondary content's 'previous' action.
  @objc private func previous() { content?.previousAction?() }

  /// Presents secondary content by embedding it within `blurView` and adding `blurView`
  /// to the view hierarchy.
  ///
  /// - Parameters:
  ///    - provider: The object providing the secondary content. This object is stored in
  ///                the `contentProvider` property and a strong reference to the content
  ///                it provides is stored in the `content` property.
  ///    - completion: The closure to invoke upon completing the animations employed to
  ///                  reveal the secondary content.
  ///    - didFinish: Indicates whether the animations finished before invocation.
  public func presentContent(for provider: SecondaryContentProvider,
                             completion: @escaping (_ didFinish: Bool) -> Void)
  {
    // Store the provider.
    contentProvider = provider

    // Store the provided content.
    content = provider.secondaryContent

    // Get the content's view controller.
    let viewController = content!.viewController

    // Add the view controller as a child.
    addChild(viewController)

    // Get the view controller's view.
    guard let childView = viewController.view
    else
    {
      fatalError("Failed to get view from secondary content controller.")
    }

    // Configure the view for autolayout.
    childView.translatesAutoresizingMaskIntoConstraints = false

    // Add the view to the blur view's content view.
    blurView.contentView.addSubview(childView)

    // Add constraints to locate the view between the two rows of buttons vertically
    // padded by the standard amount and to stretch the view horizontally padded by
    // the standard amount.
    blurView.contentView.constrain(𝗩∶[cancelButton!] - [childView] - [previousButton!],
                                   𝗛∶|-[childView]-|)

    // Create a closure that adds the blur view to the view hierarchy.
    let animations = {
      [view = view, blurView = blurView, blurFrame = blurFrame] in

      // Get the secondary controller container's view.
      guard let view = view else { return }

      // Add the blur view to the secondary controller container's view.
      view.addSubview(blurView)

      // Add constraints derived from `blurFrame`.
      view.constrain(
        𝗩∶|-blurFrame.y - [blurView] - (view.bounds.maxY - blurFrame.maxY)-|,
        𝗛∶|-blurFrame.x - [blurView] - (view.bounds.maxX - blurFrame.maxX)-|
      )
    }

    // Animate the addition of the blur view to the view hierarchy using the
    // created closure.
    UIView.transition(with: view,
                      duration: 0.25,
                      options: .allowAnimatedContent,
                      animations: animations)
    {
      [unowned self] finished in

      // Inform the view controller it has moved to a parent view controller.
      viewController.didMove(toParent: self)

      // Invoke the completion closure passing through the boolean value indicating whether
      // the animations finished before invocation.
      completion(finished)
    }
  }

  /// Returns a completion block appropriate for `action`.
  ///
  /// This method exists to encapsulate the general action-appropriate behavior so
  /// that subclasses may add to rather than replace this behavior by overriding this
  /// method instead of `dismiss(completion:)`, `cancel()`, or `confirm()`.
  ///
  /// The boolean parameter for the closure returned by this method is used to
  /// indicate whether animations finished before the closure's invocation.
  ///
  /// The default implementation informs `contentProvider` its content was dismissed
  /// with `action`.
  ///
  /// If the animations did not finish, the default implementation does nothing.
  ///
  /// - Parameter action: The dismissal action for which to generate the closure.
  ///                     This value is passed along to `contentProvider.didHide`
  /// - Returns: The closure as described above.
  open func completion(forAction action: DismissalAction) -> (Bool) -> Void
  {
    {
      [weak self] finished in

      // Check that animations finished thereby removing the blur view from the
      // view hierarchy and the secondary content from the blur view.
      guard finished else { return }

      // Inform the provider of the secondary content that the content it provided
      // has been removed.
      self?.contentProvider?.didHide(content: (self?.content!)!, dismissalAction: action)
    }
  }

  /// Removes `blurView` and the secondary content it displays. If secondary content
  /// is not being displayed then this method does nothing.
  ///
  /// - Parameter completion: The closure to be supplied to `UIView.transition`.
  public func dismiss(completion: @escaping (Bool) -> Void)
  {
    // Check that there is a controller to dismiss.
    guard let secondaryController = secondaryController else { return }

    assert(secondaryController.parent == self,
           "Retrieved `secondaryController` but it is not a child")

    // Inform the controller that it will be removed.
    secondaryController.willMove(toParent: nil)

    // Remove the controller as a child.
    secondaryController.removeFromParent()

    // Create a closure removing the controller's view from the blur view and
    // the blur view from the secondary controller container's view.
    let animations = {
      [weak blurView = blurView, weak controllerView = secondaryController.view] in

      // Remove the secondary content from the blur view.
      controllerView?.removeFromSuperview()

      // Remove the blur view from the view hierarchy.
      blurView?.removeFromSuperview()
    }

    // Animate using the created closure with the specified `completion`.
    UIView.transition(with: view,
                      duration: 0.25,
                      options: .allowAnimatedContent,
                      animations: animations,
                      completion: completion)
  }
}

public extension SecondaryControllerContainer
{
  /// Enumeration of the possible actions associated with secondary content dismissal.
  @objc enum DismissalAction: Int
  {
    /// The secondary content is being dismissed for an unknown reason.
    case none

    /// The secondary content has been cancelled by the user.
    case cancel

    /// The secondary content has been confirmed by the user.
    case confirm
  }
}

public extension SecondaryControllerContainer
{
  /// Structure for specifying the set of actions supported by a provider of
  /// secondary content.
  struct SupportedActions: OptionSet
  {
    public let rawValue: Int

    public init(rawValue: Int) { self.rawValue = rawValue }

    /// The `nil` action. This value suggests that there are no actions supported by
    /// the secondary content.
    public static let none = SupportedActions([])

    /// Inclusion of this action suggests that the secondary content provides some
    /// means of modification which can be rolled back or ignored upon the content's
    /// dismissal.
    public static let cancel = SupportedActions(rawValue: 0b0001)

    /// Inclusion of this action suggests that the secondary content provides some
    /// means of modification which can be accepted and applied upon the content's
    /// dismissal.
    public static let confirm = SupportedActions(rawValue: 0b0010)

    /// Inclusion of this action suggests that the secondary content provides an
    /// interface for some element in an ordered list of elements for which the
    /// previous element in the list may be substituted.
    public static let previous = SupportedActions(rawValue: 0b0100)

    /// Inclusion of this action suggests that the secondary content provides an
    /// interface for some element in an ordered list of elements for which the
    /// next element in the list may be substituted.
    public static let next = SupportedActions(rawValue: 0b1000)
  }
}

// MARK: - SecondaryContent

/// Protocol for classes wishing to stand in as the secondary content for an instance of
/// `SecondaryControllerContainer`.
public protocol SecondaryContent: class
{
  typealias SupportedActions = SecondaryControllerContainer.SupportedActions

  /// Action invoked by touching the right arrow, when visible
  var nextAction: (() -> Void)? { get }

  /// Action invoked by touching the left arrow, when visible
  var previousAction: (() -> Void)? { get }

  /// The view controller displaying the content to present. Default is `self` when
  /// `Self:UIViewController`.
  var viewController: UIViewController { get }

  /// Which of the available actions should be displayed.
  var supportedActions: SupportedActions { get set }

  /// Which of the displayed actions should be disabled.
  var disabledActions: SupportedActions { get set }
}

public extension SecondaryContent
{
  /// Which of the available actions should be displayed. Default is `none`.
  var supportedActions: SupportedActions { get { .none } set {} }

  /// Which of the displayed actions should be disabled. Default is `none`.
  var disabledActions: SupportedActions { get { .none } set {} }

  /// Action invoked by touching the right arrow, when visible. Default is `nil`.
  var nextAction: (() -> Void)? { nil }

  /// Action invoked by touching the left arrow, when visible. Default is `nil`.
  var previousAction: (() -> Void)? { nil }
}

public extension SecondaryContent where Self: UIViewController
{
  /// The view controller displaying the content to present. Default is `self` for
  /// `UIViewController` subclasses.
  var viewController: UIViewController { self }
}

// MARK: - SecondaryContentProvider

/// Protocol for types that provide `SecondaryContent` for `SecondaryControllerContainer`.
public protocol SecondaryContentProvider
{
  typealias DismissalAction = SecondaryControllerContainer.DismissalAction

  /// The content from which the view controller to present shall be obtained.
  var secondaryContent: SecondaryContent { get }

  /// Whether the controller returned by `secondaryContent.viewController`
  /// is currently visible.
  var isShowingContent: Bool { get }

  /// Callback invoked by an instance of `SecondaryControllerContainer` when
  /// the controller returned by `secondaryContent.viewController` is presented.
  ///
  /// - Parameter content: The previously provided `SecondaryContent`.
  func didShow(content: SecondaryContent)

  /// Callback invoked by an instance of `SecondaryControllerContainer` when the
  /// controller returned by `secondaryContent.viewController` is dismissed.
  ///
  /// - Parameters:
  ///   - content: The previously provided `SecondaryContent`.
  ///   - dismissalAction: The action triggering the dismissal of `content`.
  func didHide(content: SecondaryContent, dismissalAction: DismissalAction)
}
