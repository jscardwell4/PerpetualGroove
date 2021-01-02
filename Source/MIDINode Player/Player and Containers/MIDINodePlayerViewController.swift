//
//  MIDINodePlayerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit

// TODO: Export button beside file name

/// `UIViewController` subclass for providing an interface around an instance of `MIDINodePlayerView`.
final class MIDINodePlayerViewController: UIViewController, UITextFieldDelegate {

  /// The width of a tool button.
  private let buttonWidth: CGFloat = 42

  /// The padding between two tool buttons.
  private let buttonPadding: CGFloat = 10

  /// Sets the start of the loop to the current time.
  @IBAction
  private func startLoopAction() {
    MIDINodePlayer.loopStart = Time.current.barBeatTime
  }

  /// Sets the end of the loop to the current time.
  @IBAction
  private func stopLoopAction() {
    MIDINodePlayer.loopEnd = Time.current.barBeatTime
  }

  /// Sets the mode of the sequencer to `loop`.
  @IBAction
  private func toggleLoopAction() {
    Sequencer.mode = .loop
  }

  /// Sets the mode of the sequencer to `default`.
  @IBAction
  private func cancelLoopAction() {
    Sequencer.mode = .default
  }

  /// Sets the mode of the sequencer to `default`.
  @IBAction
  private func confirmLoopAction() {
    Sequencer.mode = .default
  }

  /// Control containing the primary tool buttons.
  @IBOutlet private(set) weak var primaryTools: ImageSegmentedControl!

  /// Stack containing the loop-related tool buttons.
  @IBOutlet private weak var loopTools: UIStackView!

  /// Handler for `primaryTools` segment selection.
  @IBAction
  private func didSelectTool(_ sender: ImageSegmentedControl) {
    MIDINodePlayer.currentTool = AnyTool(sender.selectedSegmentIndex)
  }

  /// Button for toggling loop mode.
  @IBOutlet private weak var loopToggleButton: ImageButtonView!

  /// Button for setting the loop start.
  @IBOutlet private weak var loopStartButton: ImageButtonView!

  /// Button for setting the loop end.
  @IBOutlet private weak var loopEndButton: ImageButtonView!

  /// Button for cancelling the loop.
  @IBOutlet private weak var loopCancelButton: ImageButtonView!

  /// Button for confirming the loop.
  @IBOutlet private weak var loopConfirmButton: ImageButtonView!

  /// Configures the toolbar buttons for `mode`.
  private func configure(for mode: Sequencer.Mode) {

    switch mode {

      case .loop:
        // Hide the loop toggle, show the loop-related buttons and expand `loopTools`.

        loopToggleButton.isHidden = true
        loopToolButtons.forEach {
          $0.isHidden = false
          $0.setNeedsDisplay()
        }

        loopToolsWidthConstraint.constant = 4 * buttonWidth + 3 * buttonPadding

      case .default:
        // Show the loop toggle, hide the loop-related buttons and contract `loopTools`.

        loopToggleButton.isHidden = false
        loopToggleButton.setNeedsDisplay()
        loopToolButtons.forEach { $0.isHidden = true }
        loopToolsWidthConstraint.constant = buttonWidth

    }

  }

  /// Collection of loop-related tool buttons.
  private var loopToolButtons: [ImageButtonView] {
    return [loopStartButton, loopEndButton, loopCancelButton, loopConfirmButton]
  }

  /// Width constraint for `loopTools`.
  @IBOutlet private weak var loopToolsWidthConstraint: NSLayoutConstraint!

  /// Registers `receptionist` for various notifications.
  private func setup() {
    receptionist.observe(name: .didChangeDocument, from: DocumentManager.self,
                         callback: weakCapture(of: self, block:MIDINodePlayerViewController.didChangeDocument))
    receptionist.observe(name: .willOpenDocument, from: DocumentManager.self,
                         callback: weakCapture(of: self, block:MIDINodePlayerViewController.willOpenDocument))
    receptionist.observe(name: .didSelectTool, from: MIDINodePlayer.self,
                         callback: weakCapture(of: self, block:MIDINodePlayerViewController.didSelectTool))
    receptionist.observe(name: .didEnterLoopMode, from: Sequencer.self,
                         callback: weakCapture(of: self, block:MIDINodePlayerViewController.didEnterLoopMode))
    receptionist.observe(name: .didExitLoopMode, from: Sequencer.self,
                         callback: weakCapture(of: self, block:MIDINodePlayerViewController.didExitLoopMode))
  }

  /// Overridden to run `setup()`.
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }

  /// Overridden to run `setup()`.
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  /// Overridden to clear the text in `documentName`.
  override func viewDidLoad() {

    super.viewDidLoad()

    documentName.text = nil

  }

  /// Text field for displaying and editing the name of the current document.
  @IBOutlet weak var documentName: UITextField!

  /// Spinner for indicating the opening of a file.
  @IBOutlet weak var spinner: UIImageView! {

    didSet {

      spinner?.animationImages = [
        #imageLiteral(resourceName: "spinner1"), #imageLiteral(resourceName: "spinner2"), #imageLiteral(resourceName: "spinner3"), #imageLiteral(resourceName: "spinner4"),
        #imageLiteral(resourceName: "spinner5"), #imageLiteral(resourceName: "spinner6"), #imageLiteral(resourceName: "spinner7"), #imageLiteral(resourceName: "spinner8")
        ].map { $0.image(withColor: .white) }

      spinner?.animationDuration = 0.8
      spinner?.isHidden = true

    }

  }

  /// Begins animating the `spinner`.
  private func willOpenDocument(_ notification: Notification) {
    spinner.startAnimating()
    spinner.isHidden = false
  }

  /// The responsible for displaying the `MIDIPlayerScene`.
  @IBOutlet weak var playerView: MIDINodePlayerView!

  /// Handles registration and reception of various notifications.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// Updates `documentName` with the name of the new document and stops `spinner` if necessary.
  private func didChangeDocument(_ notification: Notification) {

    documentName.text = DocumentManager.currentDocument?.localizedName

    guard spinner.isHidden == false else { return }

    spinner.stopAnimating()
    spinner.isHidden = true

  }

  /// Updates the selected segment index for `primaryTools` to match the new tool selection.
  private func didSelectTool(_ notification: Notification) {

    guard let tool = notification.selectedTool,
          primaryTools.selectedSegmentIndex != tool.rawValue
      else
    {
      return
    }

    primaryTools.selectedSegmentIndex = tool.rawValue

  }

  /// Configures controls for `loop` mode.
  private func didEnterLoopMode(_ notification: Notification) {

    UIView.animate(withDuration: 0.25) { [unowned self] in self.configure(for: .loop) }

  }

  /// Resets controls for `default` mode.
  private func didExitLoopMode(_ notification: Notification) {

    UIView.animate(withDuration: 0.25) { [unowned self] in self.configure(for: .default) }

  }

  /// Returns `true` iff there is a current document.
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return DocumentManager.currentDocument != nil
  }

  /// Resigns first responder and returns `false`.
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }

  /// Returns `true` unless `textField.text == nil`.
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {

    guard let text = textField.text else { return false }

    let fileName = DocumentManager.noncollidingFileName(for: text)

    if let currentDocument = DocumentManager.currentDocument,
      ![fileName, currentDocument.localizedName].contains(text)
    {
      textField.text = fileName
    }

    return true

  }

  /// Renames the current document unless the name has not actually changed.
  func textFieldDidEndEditing(_ textField: UITextField) {

    guard let text = textField.text,
          DocumentManager.currentDocument?.localizedName != text
      else
    {
      return
    }

    DocumentManager.currentDocument?.rename(to: text)

  }

}
