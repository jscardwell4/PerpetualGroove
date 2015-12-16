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

  /** dismissAction */
  @IBAction private func dismissAction() { dismissController() }

  private weak var controllerTool: ConfigurableToolType?

  /**
   presentControllerForTool:

   - parameter tool: ConfigurableToolType
  */
  func presentControllerForTool(tool: ConfigurableToolType) {
    let controller = tool.viewController
    guard controller.parentViewController == nil && childViewControllers.isEmpty else { return }

    addChildViewController(controller)

    let controllerView = controller.view
    controllerView.frame = playerView.bounds.insetBy(dx: 20, dy: 20)
    controllerView.translatesAutoresizingMaskIntoConstraints = false
    controllerView.backgroundColor = nil
    blurView.contentView.insertSubview(controllerView, atIndex: 0)

    view.constrain(
      controllerView.left => playerView.left + 20,
      controllerView.right => playerView.right - 20,
      controllerView.top => playerView.top + 20,
      controllerView.bottom => playerView.bottom - 20
    )

    controller.didMoveToParentViewController(self)

    blurView.hidden = false

    tool.didShowViewController(controller)

    controllerTool = tool
  }

  /** dismissController */
  func dismissController() {
    guard let tool = controllerTool where tool.isShowingViewController else { return }
    let controller = tool.viewController
    guard controller.parentViewController === self else { return }
    controller.willMoveToParentViewController(nil)
    controller.removeFromParentViewController()
    if controller.isViewLoaded() { controller.view.removeFromSuperview() }
    blurView.hidden = true
    tool.didHideViewController(controller)
    controllerTool = nil
  }

  /** setup */
  private func setup() { initializeReceptionist(); MIDIPlayer.playerViewController = self }

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