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

final class MIDIPlayerViewController: UIViewController {

  @IBOutlet private weak var blurView: UIVisualEffectView!

  private var constructingLoop = false

  /** startLoopAction */
  @IBAction private func startLoopAction() {
    guard Sequencer.mode == .Loop && !constructingLoop else {
      fatalError("This method should only be called when a loop is under construction")
    }
  }

  /** stopLoopAction */
  @IBAction private func stopLoopAction() {
    guard Sequencer.mode == .Loop && constructingLoop else {
      fatalError("This method should only be called when a loop is under construction")
    }
  }

  /** toggleLoopAction */
  @IBAction private func toggleLoopAction() {
    switch loopToggleButton.selected {
      // At this point the button's `selected` property has yet to be updated for the current event
      case true: Sequencer.mode = .Default
      case false: Sequencer.mode = .Loop
    }
  }

  @IBOutlet weak var loopStartButton: ImageButtonView!
  @IBOutlet weak var loopEndButton: ImageButtonView!
  @IBOutlet weak var loopToggleButton: ImageButtonView!

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
    documentName.text = MIDIDocumentManager.currentDocument?.localizedName
    if spinner.hidden == false {
      spinner.stopAnimating()
      spinner.hidden = true
    }
  }

  private func didSelectTool(notification: NSNotification) {
    guard let tool = notification.selectedTool else { return }
    if tools.selectedSegmentIndex != tool.rawValue { tools.selectedSegmentIndex = tool.rawValue }
  }

  /**
   didEnterLoopMode:

   - parameter notification: NSNotification
  */
  private func didEnterLoopMode(notification: NSNotification) {}

  /**
   didExitLoopMode:

   - parameter notification: NSNotification
  */
  private func didExitLoopMode(notification: NSNotification) {}


  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard receptionist.count == 0 else { return }

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.didChangeDocument))
    receptionist.observe(MIDIDocumentManager.Notification.WillOpenDocument,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.willOpenDocument))
    receptionist.observe(MIDIPlayer.Notification.DidSelectTool,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didSelectTool))
    receptionist.observe(Sequencer.Notification.DidEnterLoopMode,
                    from: Sequencer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didEnterLoopMode))
    receptionist.observe(Sequencer.Notification.DidExitLoopMode,
                    from: Sequencer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didExitLoopMode))

  }

  // MARK: - Tools

  @IBOutlet private(set) weak var tools: ImageSegmentedControl!

  @IBAction private func didSelectTool(sender: ImageSegmentedControl) {
    MIDIPlayer.currentTool = Tool(sender.selectedSegmentIndex)
  }

}

extension MIDIPlayerViewController: UITextFieldDelegate {

  /**
  textFieldShouldBeginEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
    return MIDIDocumentManager.currentDocument != nil
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
              fileName = MIDIDocumentManager.noncollidingFileName(text) else { return false }

    if let currentDocument = MIDIDocumentManager.currentDocument
      where [fileName, currentDocument.localizedName] ∌ text { textField.text = fileName }

    return true
  }

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(textField: UITextField) {
    guard let text = textField.text
      where MIDIDocumentManager.currentDocument?.localizedName != text else { return }
    MIDIDocumentManager.currentDocument?.renameTo(text)
  }
}