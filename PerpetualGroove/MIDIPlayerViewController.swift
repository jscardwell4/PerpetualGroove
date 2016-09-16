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
  @IBAction fileprivate func startLoopAction() { MIDIPlayer.loopStart = Sequencer.transport.time.barBeatTime }

  fileprivate let buttonWidth: CGFloat = 42
  fileprivate let buttonPadding: CGFloat = 10

  /** stopLoopAction */
  @IBAction fileprivate func stopLoopAction() { MIDIPlayer.loopEnd = Sequencer.transport.time.barBeatTime }

  /** toggleLoopAction */
  @IBAction fileprivate func toggleLoopAction() { Sequencer.mode = .Loop }

  /** cancelLoopAction */
  @IBAction fileprivate func cancelLoopAction() { Sequencer.mode = .Default }

  /** confirmLoopAction */
  @IBAction fileprivate func confirmLoopAction() { MIDIPlayer.shouldInsertLoops = true;  Sequencer.mode = .Default }

  // MARK: - Tools

  @IBOutlet fileprivate(set) weak var primaryTools: ImageSegmentedControl!

  @IBOutlet fileprivate weak var loopTools: UIStackView!

  @IBAction fileprivate func didSelectTool(_ sender: ImageSegmentedControl) {
    MIDIPlayer.currentTool = Tool(sender.selectedSegmentIndex)
  }

  @IBOutlet fileprivate weak var loopToggleButton: ImageButtonView!

  @IBOutlet fileprivate weak var loopStartButton: ImageButtonView!
  @IBOutlet fileprivate weak var loopEndButton: ImageButtonView!
  @IBOutlet fileprivate weak var loopCancelButton: ImageButtonView!
  @IBOutlet fileprivate weak var loopConfirmButton: ImageButtonView!

  fileprivate var loopToolButtons: [ImageButtonView] { return [loopStartButton, loopEndButton, loopCancelButton, loopConfirmButton] }

  @IBOutlet fileprivate weak var loopToolsWidthConstraint: NSLayoutConstraint!

  /** setup */
  fileprivate func setup() { initializeReceptionist() }

  /**
   init:bundle:

   - parameter nibNameOrNil: String?
   - parameter nibBundleOrNil: NSBundle?
  */
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
        UIImage(named: "spinner\($0)")?.imageWithColor(UIColor.white)
      }
      spinner?.animationDuration = 0.8
      spinner?.isHidden = true
    }
  }

  /**
  willOpenDocument:

  - parameter notification: NSNotification
  */
  fileprivate func willOpenDocument(_ notification: Notification) {
    spinner.startAnimating()
    spinner.isHidden = false
  }


  // MARK: - Scene-related properties

  @IBOutlet weak var playerView: MIDIPlayerView!

  // MARK: - Managing state

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  /**
  didChangeDocument:

  - parameter notification: NSNotification
  */
  fileprivate func didChangeDocument(_ notification: Notification) {
    documentName.text = DocumentManager.currentDocument?.localizedName
    if spinner.isHidden == false {
      spinner.stopAnimating()
      spinner.isHidden = true
    }
  }

  fileprivate func didSelectTool(_ notification: Notification) {
    guard let tool = notification.selectedTool else { return }
    if primaryTools.selectedSegmentIndex != tool.rawValue {
      primaryTools.selectedSegmentIndex = tool.rawValue
    }
  }

  /**
   didEnterLoopMode:

   - parameter notification: NSNotification
  */
  fileprivate func didEnterLoopMode(_ notification: Notification) {
    UIView.animate(withDuration: 0.25, animations: {
      [unowned self] in

      self.loopToggleButton.isHidden = true
      self.loopToolButtons.forEach { $0.isHidden = false; $0.setNeedsDisplay() }
      self.loopToolsWidthConstraint.constant = 4 * self.buttonWidth + 3 * self.buttonPadding
    }) 
  }

  /**
   didExitLoopMode:

   - parameter notification: NSNotification
  */
  fileprivate func didExitLoopMode(_ notification: Notification) {
    UIView.animate(withDuration: 0.25, animations: {
      [unowned self] in

      self.loopToggleButton.isHidden = false
      self.loopToggleButton.setNeedsDisplay()
      self.loopToolButtons.forEach { $0.isHidden = true }
      self.loopToolsWidthConstraint.constant = self.buttonWidth
    }) 
  }


  /** initializeReceptionist */
  fileprivate func initializeReceptionist() {

    guard receptionist.count == 0 else { return }

    receptionist.observe(name: DocumentManager.NotificationName.didChangeDocument.rawValue,
                    from: DocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.didChangeDocument))
    receptionist.observe(name: DocumentManager.NotificationName.willOpenDocument.rawValue,
                    from: DocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.willOpenDocument))
    receptionist.observe(name: MIDIPlayer.NotificationName.didSelectTool.rawValue,
                    from: MIDIPlayer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didSelectTool))
    receptionist.observe(name: Sequencer.NotificationName.didEnterLoopMode.rawValue,
                    from: Sequencer.self,
                callback: weakMethod(self, MIDIPlayerViewController.didEnterLoopMode))
    receptionist.observe(name: Sequencer.NotificationName.didExitLoopMode.rawValue,
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
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return DocumentManager.currentDocument != nil
  }

  /**
  textFieldShouldReturn:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }

  /**
  textFieldShouldEndEditing:

  - parameter textField: UITextField

  - returns: Bool
  */
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {

    guard let text = textField.text,
              let fileName = DocumentManager.noncollidingFileName(text) else { return false }

    if let currentDocument = DocumentManager.currentDocument
      , ![fileName, currentDocument.localizedName].contains(text) { textField.text = fileName }

    return true
  }

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let text = textField.text
      , DocumentManager.currentDocument?.localizedName != text else { return }
    DocumentManager.currentDocument?.renameTo(text)
  }
}
