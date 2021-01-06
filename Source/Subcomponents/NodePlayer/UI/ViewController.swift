//
//  PlayerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//
import MIDI
import MoonKit
import SpriteKit
import UIKit

public extension Container
{
  /// `UIViewController` subclass for providing an interface around an instance of `View`.
  final class ViewController: UIViewController, UITextFieldDelegate
  {
    /// The width of a tool button.
    private let buttonWidth: CGFloat = 42

    /// The padding between two tool buttons.
    private let buttonPadding: CGFloat = 10

    /// Sets the start of the loop to the current time.
    @IBAction
    private func startLoopAction()
    {
      fatalError("\(#function) not yet implemented.")
//    NodePlayer.loopStart = Time.current?.barBeatTime ?? .zero
    }

    /// Sets the end of the loop to the current time.
    @IBAction
    private func stopLoopAction()
    {
      fatalError("\(#function) not yet implemented.")
//    NodePlayer.loopEnd = Time.current?.barBeatTime ?? .zero
    }

    /// Sets the mode of the sequencer to `loop`.
    @IBAction
    private func toggleLoopAction()
    {
      fatalError("\(#function) not yet implemented.")
//    Sequencer.mode = .loop
    }

    /// Sets the mode of the sequencer to `default`.
    @IBAction
    private func cancelLoopAction()
    {
      fatalError("\(#function) not yet implemented.")
//    Sequencer.mode = .default
    }

    /// Sets the mode of the sequencer to `default`.
    @IBAction
    private func confirmLoopAction()
    {
      fatalError("\(#function) not yet implemented.")
//    Sequencer.mode = .default
    }

    /// Control containing the primary tool buttons.
    @IBOutlet private(set) var primaryTools: ImageSegmentedControl!

    /// Stack containing the loop-related tool buttons.
    @IBOutlet private var loopTools: UIStackView!

    /// Handler for `primaryTools` segment selection.
    @IBAction
    private func didSelectTool(_ sender: ImageSegmentedControl)
    {
      Player.currentTool = AnyTool(sender.selectedSegmentIndex)
    }

    /// Button for toggling loop mode.
    @IBOutlet private var loopToggleButton: ImageButtonView!

    /// Button for setting the loop start.
    @IBOutlet private var loopStartButton: ImageButtonView!

    /// Button for setting the loop end.
    @IBOutlet private var loopEndButton: ImageButtonView!

    /// Button for cancelling the loop.
    @IBOutlet private var loopCancelButton: ImageButtonView!

    /// Button for confirming the loop.
    @IBOutlet private var loopConfirmButton: ImageButtonView!

    /// Configures the toolbar buttons for `mode`.
//  private func configure(for mode: Sequencer.Mode) {
//
//    switch mode {
//
//      case .loop:
//        // Hide the loop toggle, show the loop-related buttons and expand `loopTools`.
//
//        loopToggleButton.isHidden = true
//        loopToolButtons.forEach {
//          $0.isHidden = false
//          $0.setNeedsDisplay()
//        }
//
//        loopToolsWidthConstraint.constant = 4 * buttonWidth + 3 * buttonPadding
//
//      case .default:
//        // Show the loop toggle, hide the loop-related buttons and contract `loopTools`.
//
//        loopToggleButton.isHidden = false
//        loopToggleButton.setNeedsDisplay()
//        loopToolButtons.forEach { $0.isHidden = true }
//        loopToolsWidthConstraint.constant = buttonWidth
//
//    }
//
//  }

    /// Collection of loop-related tool buttons.
    private var loopToolButtons: [ImageButtonView]
    {
      return [loopStartButton, loopEndButton, loopCancelButton, loopConfirmButton]
    }

    /// Width constraint for `loopTools`.
    @IBOutlet private var loopToolsWidthConstraint: NSLayoutConstraint!

    /// Registers `receptionist` for various notifications.
    private func setup()
    {
//    fatalError("\(#function) not yet implemented.")
//    receptionist.observe(name: .didChangeDocument, from: DocumentManager.self,
//                         callback: weakCapture(of: self, block:ViewController.didChangeDocument))
//    receptionist.observe(name: .willOpenDocument, from: DocumentManager.self,
//                         callback: weakCapture(of: self, block:ViewController.willOpenDocument))
//    receptionist.observe(name: .didSelectTool, from: NodePlayer.self,
//                         callback: weakCapture(of: self, block:ViewController.didSelectTool))
//    receptionist.observe(name: .didEnterLoopMode, from: Sequencer.self,
//                         callback: weakCapture(of: self, block:ViewController.didEnterLoopMode))
//    receptionist.observe(name: .didExitLoopMode, from: Sequencer.self,
//                         callback: weakCapture(of: self, block:ViewController.didExitLoopMode))
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

      documentName.text = nil
    }

    /// Text field for displaying and editing the name of the current document.
    @IBOutlet public var documentName: UITextField!

    /// Spinner for indicating the opening of a file.
    @IBOutlet public var spinner: UIImageView!
    {
      didSet
      {
        spinner?.animationImages = [
          #imageLiteral(resourceName: "spinner1"), #imageLiteral(resourceName: "spinner2"), #imageLiteral(resourceName: "spinner3"), #imageLiteral(resourceName: "spinner4"),
          #imageLiteral(resourceName: "spinner5"), #imageLiteral(resourceName: "spinner6"), #imageLiteral(resourceName: "spinner7"), #imageLiteral(resourceName: "spinner8"),
        ].map { $0.image(withColor: .white) }

        spinner?.animationDuration = 0.8
        spinner?.isHidden = true
      }
    }

    /// Begins animating the `spinner`.
    private func willOpenDocument(_: Notification)
    {
      spinner.startAnimating()
      spinner.isHidden = false
    }

    /// The responsible for displaying the `MIDIPlayerScene`.
    @IBOutlet public var playerView: View!

    /// Handles registration and reception of various notifications.
    private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

    /// Updates `documentName` with the name of the new document and stops `spinner` if necessary.
    private func didChangeDocument(_: Notification)
    {
      fatalError("\(#function) not yet implemented.")
//    documentName.text = DocumentManager.currentDocument?.localizedName
//
//    guard spinner.isHidden == false else { return }
//
//    spinner.stopAnimating()
//    spinner.isHidden = true
    }

    /// Updates the selected segment index for `primaryTools` to match the new tool selection.
    private func didSelectTool(_ notification: Notification)
    {
      guard let tool = notification.selectedTool,
            primaryTools.selectedSegmentIndex != tool.rawValue
      else
      {
        return
      }

      primaryTools.selectedSegmentIndex = tool.rawValue
    }

    /// Configures controls for `loop` mode.
    private func didEnterLoopMode(_: Notification)
    {
      fatalError("\(#function) not yet implemented.")
//    UIView.animate(withDuration: 0.25) { [unowned self] in self.configure(for: .loop) }
    }

    /// Resets controls for `default` mode.
    private func didExitLoopMode(_: Notification)
    {
      fatalError("\(#function) not yet implemented.")
//    UIView.animate(withDuration: 0.25) { [unowned self] in self.configure(for: .default) }
    }

    /// Returns `true` iff there is a current document.
    public func textFieldShouldBeginEditing(_: UITextField) -> Bool
    {
      fatalError("\(#function) not yet implemented.")
//    return DocumentManager.currentDocument != nil
    }

    /// Resigns first responder and returns `false`.
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
      textField.resignFirstResponder()
      return false
    }

    /// Returns `true` unless `textField.text == nil`.
    public func textFieldShouldEndEditing(_: UITextField) -> Bool
    {
      fatalError("\(#function) not yet implemented.")
//    guard let text = textField.text else { return false }
//
//    let fileName = DocumentManager.noncollidingFileName(for: text)
//
//    if let currentDocument = DocumentManager.currentDocument,
//      ![fileName, currentDocument.localizedName].contains(text)
//    {
//      textField.text = fileName
//    }
//
//    return true
    }

    /// Renames the current document unless the name has not actually changed.
    public func textFieldDidEndEditing(_: UITextField)
    {
      fatalError("\(#function) not yet implemented.")
//    guard let text = textField.text,
//          DocumentManager.currentDocument?.localizedName != text
//      else
//    {
//      return
//    }
//
//    DocumentManager.currentDocument?.rename(to: text)
    }
  }
}
