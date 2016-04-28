//
//  MIDIPlayerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit
import Triump
import Eveleth

// TODO: Export button beside file name

final class MIDIPlayerViewController: UIViewController {

  /** startLoopAction */
  @IBAction private func startLoopAction() { MIDIPlayer.loopStart = Sequencer.transport.time.barBeatTime }

  private let buttonWidth: CGFloat = 42
  private let buttonPadding: CGFloat = 10

  /** stopLoopAction */
  @IBAction private func stopLoopAction() { MIDIPlayer.loopEnd = Sequencer.transport.time.barBeatTime }

  /** toggleLoopAction */
  @IBAction private func toggleLoopAction() { Sequencer.mode = .Loop }

  /** cancelLoopAction */
  @IBAction private func cancelLoopAction() { Sequencer.mode = .Default }

  /** confirmLoopAction */
  @IBAction private func confirmLoopAction() { MIDIPlayer.shouldInsertLoops = true;  Sequencer.mode = .Default }

  // MARK: - Tools

  @IBOutlet private(set) weak var primaryTools: ImageSegmentedControl!

  @IBOutlet private weak var loopTools: UIStackView!

  @IBAction private func didSelectTool(sender: ImageSegmentedControl) {
    MIDIPlayer.currentTool = Tool(sender.selectedSegmentIndex)
  }

  @IBOutlet private weak var loopToggleButton: ImageButtonView!

  @IBOutlet private weak var loopStartButton: ImageButtonView!
  @IBOutlet private weak var loopEndButton: ImageButtonView!
  @IBOutlet private weak var loopCancelButton: ImageButtonView!
  @IBOutlet private weak var loopConfirmButton: ImageButtonView!

  private var loopToolButtons: [ImageButtonView] { return [loopStartButton, loopEndButton, loopCancelButton, loopConfirmButton] }

  @IBOutlet private weak var loopToolsWidthConstraint: NSLayoutConstraint!

  /** setup */
  private func setup() { initializeReceptionist() }

  /**
   init:bundle:

   - parameter nibNameOrNil: String?
   - parameter nibBundleOrNil: NSBundle?
  */
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }

  /**
   init:

   - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  /** viewDidLoad */
  override func viewDidLoad() { super.viewDidLoad(); documentName.text = nil }

  // MARK: - Files

  @IBOutlet weak var documentName: UITextField!

  @IBOutlet weak var spinner: UIImageView! {
    didSet {
      spinner?.animationImages = (1...8).flatMap{
        UIImage(named: "spinner\($0)")?.imageWithColor(.whiteColor())
      }
      spinner?.animationDuration = 0.8
      spinner?.hidden = true
    }
  }

  /**
  willOpenDocument:

  - parameter notification: NSNotification
  */
  private func willOpenDocument(notification: NSNotification) {
    spinner.startAnimating()
    spinner.hidden = false
  }


  // MARK: - Scene-related properties

  @IBOutlet weak var playerView: MIDIPlayerView!

  // MARK: - Managing state

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  /**
  didChangeDocument:

  - parameter notification: NSNotification
  */
  private func didChangeDocument(notification: NSNotification) {
    documentName.text = DocumentManager.currentDocument?.localizedName
    if spinner.hidden == false {
      spinner.stopAnimating()
      spinner.hidden = true
    }
  }

  private func didSelectTool(notification: NSNotification) {
    guard let tool = notification.selectedTool else { return }
    if primaryTools.selectedSegmentIndex != tool.rawValue {
      primaryTools.selectedSegmentIndex = tool.rawValue
    }
  }

  /**
   didEnterLoopMode:

   - parameter notification: NSNotification
  */
  private func didEnterLoopMode(notification: NSNotification) {
    UIView.animateWithDuration(0.25) {
      [unowned self] in

      self.loopToggleButton.hidden = true
      self.loopToolButtons.forEach { $0.hidden = false; $0.setNeedsDisplay() }
      self.loopToolsWidthConstraint.constant = 4 * self.buttonWidth + 3 * self.buttonPadding
    }
  }

  /**
   didExitLoopMode:

   - parameter notification: NSNotification
  */
  private func didExitLoopMode(notification: NSNotification) {
    UIView.animateWithDuration(0.25) {
      [unowned self] in

      self.loopToggleButton.hidden = false
      self.loopToggleButton.setNeedsDisplay()
      self.loopToolButtons.forEach { $0.hidden = true }
      self.loopToolsWidthConstraint.constant = self.buttonWidth
    }
  }


  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard receptionist.count == 0 else { return }

    receptionist.observe(notification: DocumentManager.Notification.DidChangeDocument,
                    from: DocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.didChangeDocument))
    receptionist.observe(notification: DocumentManager.Notification.WillOpenDocument,
                    from: DocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.willOpenDocument))
    receptionist.observe(notification: MIDIPlayer.Notification.DidSelectTool,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didSelectTool))
    receptionist.observe(notification: Sequencer.Notification.DidEnterLoopMode,
                    from: Sequencer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didEnterLoopMode))
    receptionist.observe(notification: Sequencer.Notification.DidExitLoopMode,
                    from: Sequencer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didExitLoopMode))

  }

}

extension MIDIPlayerViewController: UITextFieldDelegate {

  /**
  textFieldShouldBeginEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    return DocumentManager.currentDocument != nil
  }

  /**
  textFieldShouldReturn:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }

  /**
  textFieldShouldEndEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldEndEditing(textField: UITextField) -> Bool {

    guard let text = textField.text,
              fileName = DocumentManager.noncollidingFileName(text) else { return false }

    if let currentDocument = DocumentManager.currentDocument
      where ![fileName, currentDocument.localizedName].contains(text) { textField.text = fileName }

    return true
  }

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(textField: UITextField) {
    guard let text = textField.text
      where DocumentManager.currentDocument?.localizedName != text else { return }
    DocumentManager.currentDocument?.renameTo(text)
  }
}