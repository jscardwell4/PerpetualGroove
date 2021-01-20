//
//  PlayerViewController.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/8/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import Foundation
import MIDI
import MoonDev
import SpriteKit
import UIKit

// MARK: - PlayerViewController

/// `UIViewController` subclass for providing an interface around an instance of `View`.
@available(iOS 14.0, *)
public final class PlayerViewController: UIViewController, UITextFieldDelegate
{
  /// The view responsible for displaying the `PlayerScene`.
  @IBOutlet public var playerView: PlayerSKView!

  /// The width of a tool button.
  private let buttonWidth: CGFloat = 42

  /// The padding between two tool buttons.
  private let buttonPadding: CGFloat = 10

  /// Sets the start of the loop to the current time.
  @IBAction private func startLoopAction() { sequencer.markLoopStart() }

  /// Sets the end of the loop to the current time.
  @IBAction private func stopLoopAction() { sequencer.markLoopEnd() }

  /// Sets the mode of the sequencer to `loop`.
  @IBAction private func toggleLoopAction() { sequencer.enterLoopMode() }

  /// Sets the mode of the sequencer to `default`.
  @IBAction private func cancelLoopAction() { sequencer.exitLoopMode() }

  /// Sets the mode of the sequencer to `default`.
  @IBAction private func confirmLoopAction() { sequencer.exitLoopMode() }

  /// Control containing the primary tool buttons.
  @IBOutlet private(set) var primaryTools: ImageSegmentedControl?

  /// Stack containing the loop-related tool buttons.
  @IBOutlet private var loopTools: UIStackView?

  /// Handler for `primaryTools` segment selection.
  @IBAction
  private func didSelectTool(_ sender: ImageSegmentedControl)
  {
    player.currentTool = AnyTool(sender.selectedSegmentIndex)
  }

  /// Button for toggling loop mode.
  @IBOutlet private var loopToggleButton: ImageButtonView?

  /// Button for setting the loop start.
  @IBOutlet private var loopStartButton: ImageButtonView?

  /// Button for setting the loop end.
  @IBOutlet private var loopEndButton: ImageButtonView?

  /// Button for cancelling the loop.
  @IBOutlet private var loopCancelButton: ImageButtonView?

  /// Button for confirming the loop.
  @IBOutlet private var loopConfirmButton: ImageButtonView?

  /// Configures the toolbar buttons for `mode`.
  private func configure(for mode: Mode)
  {
    switch mode
    {
      case .loop:
        // Hide the loop toggle, show the loop-related buttons and expand `loopTools`.

        loopToggleButton?.isHidden = true
        loopToolButtons.forEach
        {
          $0?.isHidden = false
          $0?.setNeedsDisplay()
        }

        loopToolsWidthConstraint?.constant = 4 * buttonWidth + 3 * buttonPadding

      case .linear:
        // Show the loop toggle, hide the loop-related buttons and contract `loopTools`.

        loopToggleButton?.isHidden = false
        loopToggleButton?.setNeedsDisplay()
        loopToolButtons.forEach { $0?.isHidden = true }
        loopToolsWidthConstraint?.constant = buttonWidth
    }
  }

  /// Collection of loop-related tool buttons.
  private var loopToolButtons: [ImageButtonView?]
  {
    [loopStartButton, loopEndButton, loopCancelButton, loopConfirmButton]
  }

  /// Width constraint for `loopTools`.
  @IBOutlet private var loopToolsWidthConstraint: NSLayoutConstraint?

  /// Subscription for the player's current tool.
  private var currentToolSubscription: Cancellable?

  /// Subscription for the controller's current mode.
  private var currentModeSubscription: Cancellable?

  /// Flag used to activate and deactivate the progress spinner.
  public var activeSpinner: Bool = false {
    didSet {
      guard activeSpinner != oldValue else { return }
      if activeSpinner, let spinner = spinner, !spinner.isAnimating
      {
        spinner.startAnimating()
        spinner.isHidden = false
      } else if !activeSpinner, let spinner = spinner, spinner.isAnimating {
        spinner.stopAnimating()
        spinner.isHidden = true
      }
    }
  }

  /// Configures subscriptions.
  private func setup()
  {
    currentToolSubscription = player.$currentTool.sink
    {
      self.primaryTools?.selectedSegmentIndex = $0.rawValue
    }
    currentModeSubscription = sequencer.$mode.sink
    {
      newMode in UIView.animate(withDuration: 0.25) { self.configure(for: newMode) }
    }
  }

  /// Overridden to run `setup()`.
  override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
  {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }

  /// Overridden to run `setup()`.
  public required init?(coder aDecoder: NSCoder)
  {
    super.init(coder: aDecoder)
    setup()
  }

  /// Overridden to clear the text in `documentName`.
  override public func viewDidLoad()
  {
    super.viewDidLoad()
    documentName?.text = nil
  }

  public var documentManager: DocumentManager?

  /// Text field for displaying and editing the name of the current document.
  @IBOutlet public var documentName: UITextField?

  /// Spinner for indicating the opening of a file.
  @IBOutlet public var spinner: UIImageView?
  {
    didSet
    {
      guard let spinner = spinner
      else
      {
        return
      }

      spinner.animationImages = [
        UIImage(named: "spinner1", in: Bundle.module, with: nil)!,
        UIImage(named: "spinner2", in: Bundle.module, with: nil)!,
        UIImage(named: "spinner3", in: Bundle.module, with: nil)!,
        UIImage(named: "spinner4", in: Bundle.module, with: nil)!,
        UIImage(named: "spinner5", in: Bundle.module, with: nil)!,
        UIImage(named: "spinner6", in: Bundle.module, with: nil)!,
        UIImage(named: "spinner7", in: Bundle.module, with: nil)!,
        UIImage(named: "spinner8", in: Bundle.module, with: nil)!
      ]
      .map { $0.image(withColor: .white) }

      spinner.animationDuration = 0.8
      spinner.isHidden = true
    }
  }

  /// Returns `true` iff there is a current document.
  public func textFieldShouldBeginEditing(_: UITextField) -> Bool
  {
    documentManager?.currentDocument != nil
  }

  /// Resigns first responder and returns `false`.
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool
  {
    textField.resignFirstResponder()
    return false
  }

  /// Returns `true` unless `textField.text == nil`.
  public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
  {
    guard let text = textField.text else { return false }

    if let fileName = documentManager?.noncollidingFileName(for: text),
       let currentDocument = documentManager?.currentDocument,
       ![fileName, currentDocument.localizedName].contains(text)
    {
      textField.text = fileName
    }

    return true
  }

  /// Renames the current document unless the name has not actually changed.
  public func textFieldDidEndEditing(_ textField: UITextField)
  {
    guard let text = textField.text,
          let currentName = documentManager?.currentDocument?.localizedName,
          currentName != text
    else
    {
      return
    }

    documentManager?.currentDocument?.rename(to: text)
  }
}

// MARK: - DocumentManager

public protocol DocumentManager
{
  var currentDocument: Document? { get }

  func noncollidingFileName(for fileName: String) -> String

  var projectedValue: Published<Document?>.Publisher { get }
}

// MARK: - Document

public protocol Document
{
  var localizedName: String { get }

  func rename(to newName: String)
}
