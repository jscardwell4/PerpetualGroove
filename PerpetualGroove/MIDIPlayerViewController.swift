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

  var toolViewController: UIViewController? {
    didSet {
      guard toolViewController != oldValue else { return }
      if let oldController = oldValue {
        oldController.willMoveToParentViewController(nil)
        oldController.removeFromParentViewController()
        if oldController.isViewLoaded() {
          oldController.view.removeFromSuperview()
        }
      }
      if let newController = toolViewController {
        addChildViewController(newController)
        blurView.contentView.addSubview(newController.view)
        newController.didMoveToParentViewController(self)
        blurView.hidden = false
      } else {
        blurView.hidden = true
      }
    }
  }

  @IBAction private func didSelectTool(sender: ImageSegmentedControl) {
    switch sender.selectedSegmentIndex {
      case 0:                               MIDIPlayer.configureGenerator()
      case 1:                               MIDIPlayer.currentTool = .Add
      case 2:                               MIDIPlayer.currentTool = .Remove
      case 3:                               MIDIPlayer.currentTool = .Generator
      case ImageSegmentedControl.NoSegment: MIDIPlayer.currentTool = .None
      default:                              break
    }
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
    guard let text = textField.text,
      currentDocument = MIDIDocumentManager.currentDocument where currentDocument.localizedName != text else { return }
    currentDocument.renameTo(text)
  }
}