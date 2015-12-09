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

  @IBOutlet weak var blurView: UIVisualEffectView!

  /** dismissAction */
  @IBAction private func dismissAction() {
    MIDIPlayer.dismissToolViewController()
  }

  /** setup */
  private func setup() {
    initializeReceptionist()
    MIDIPlayer.playerViewController = self
  }

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
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    documentName.text = nil
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

  // MARK: - Tools

  @IBOutlet private(set) weak var tools: ImageSegmentedControl!

  @IBAction private func didSelectTool(sender: ImageSegmentedControl) {
    MIDIPlayer.currentTool = MIDIPlayer.Tool(rawValue: sender.selectedSegmentIndex) ?? .None
  }

}

//extension MIDIPlayerViewController: UIGestureRecognizerDelegate {
//
//  /**
//   gestureRecognizer:shouldReceiveTouch:
//
//   - parameter gestureRecognizer: UIGestureRecognizer
//   - parameter touch: UITouch
//
//    - returns: Bool
//  */
//  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
//    guard let toolViewController = toolViewController where toolViewController.isViewLoaded() else { return false }
//    let point = touch.locationInView(toolViewController.view)
//    let result = !toolViewController.view.pointInside(point, withEvent: nil)
//    return result
//  }
//
//}

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
    guard let text = textField.text where MIDIDocumentManager.currentDocument?.localizedName != text else { return }
    MIDIDocumentManager.currentDocument?.renameTo(text)
  }
}