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

  static var currentInstance: MIDIPlayerViewController { return RootViewController.currentInstance.playerViewController }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    documentName.text = nil
    initializeReceptionist()
  }

  // MARK: - Files

  @IBOutlet weak var documentName: UITextField!

  @IBOutlet weak var spinner: UIImageView! {
    didSet {
      spinner?.animationImages = (1 ... 8).flatMap({UIImage(named: "spinner\($0)")?.imageWithColor(.whiteColor())})
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

  // MARK: - Scene-relatd properties

  @IBOutlet weak var midiPlayerView: MIDIPlayerView!

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

  /** initializeReceptionist */
  private func initializeReceptionist() {

    guard receptionist.count == 0 else { return }

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.didChangeDocument))
    receptionist.observe(MIDIDocumentManager.Notification.WillOpenDocument,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, MIDIPlayerViewController.willOpenDocument))

  }

  private var activeTool: Tool = .Add {
    didSet {
      logDebug("activeTool = \(activeTool)")
    }
  }

  @IBAction private func didSelectTool(sender: ImageSegmentedControl) {
    switch sender.selectedSegmentIndex {
      case 0:  activeTool = .Add
      case 1:  activeTool = .Remove
      case 2:  activeTool = .Generator
      default: break
    }
  }

}

extension MIDIPlayerViewController {
  enum Tool { case Add, Remove, Generator }
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

    if text != fileName { textField.text = fileName }
    return true
  }

  /**
  textFieldDidEndEditing:

  - parameter textField: UITextField
  */
  func textFieldDidEndEditing(textField: UITextField) {
    guard let text = textField.text else { return }

    MIDIDocumentManager.currentDocument?.renameTo(text)
  }
}