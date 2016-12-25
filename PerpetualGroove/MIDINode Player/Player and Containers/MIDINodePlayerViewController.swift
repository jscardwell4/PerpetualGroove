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

final class MIDINodePlayerViewController: UIViewController {

  private let buttonWidth: CGFloat = 42
  private let buttonPadding: CGFloat = 10

  @IBAction private func startLoopAction() {
    MIDINodePlayer.loopStart = Sequencer.transport.time.barBeatTime
  }

  @IBAction private func stopLoopAction() {
    MIDINodePlayer.loopEnd = Sequencer.transport.time.barBeatTime
  }

  @IBAction private func toggleLoopAction() {
    Sequencer.mode = .loop
  }

  @IBAction private func cancelLoopAction() {
    Sequencer.mode = .default
  }

  @IBAction private func confirmLoopAction() {
    MIDINodePlayer.shouldInsertLoops = true;  Sequencer.mode = .default
  }

  // MARK: - Tools

  @IBOutlet private(set) weak var primaryTools: ImageSegmentedControl!

  @IBOutlet private weak var loopTools: UIStackView!

  @IBAction private func didSelectTool(_ sender: ImageSegmentedControl) {
    MIDINodePlayer.currentTool = AnyTool(sender.selectedSegmentIndex)
  }

  @IBOutlet private weak var loopToggleButton:  ImageButtonView!
  @IBOutlet private weak var loopStartButton:   ImageButtonView!
  @IBOutlet private weak var loopEndButton:     ImageButtonView!
  @IBOutlet private weak var loopCancelButton:  ImageButtonView!
  @IBOutlet private weak var loopConfirmButton: ImageButtonView!

  private var loopToolButtons: [ImageButtonView] {
    return [loopStartButton, loopEndButton, loopCancelButton, loopConfirmButton]
  }

  @IBOutlet private weak var loopToolsWidthConstraint: NSLayoutConstraint!

  private func setup() { initializeReceptionist() }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    documentName.text = nil
  }

  // MARK: - Files

  @IBOutlet weak var documentName: UITextField!

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

  private func willOpenDocument(_ notification: Notification) {
    spinner.startAnimating()
    spinner.isHidden = false
  }


  // MARK: - Scene-related properties

  @IBOutlet weak var playerView: MIDINodePlayerView!

  // MARK: - Managing state

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  private func didChangeDocument(_ notification: Notification) {

    documentName.text = DocumentManager.currentDocument?.localizedName

    guard spinner.isHidden == false else { return }

    spinner.stopAnimating()
    spinner.isHidden = true

  }

  private func didSelectTool(_ notification: Notification) {

    guard
      let tool = notification.selectedTool,
      primaryTools.selectedSegmentIndex != tool.rawValue
      else
    {
      return
    }

    primaryTools.selectedSegmentIndex = tool.rawValue

  }

  private func didEnterLoopMode(_ notification: Notification) {

    UIView.animate(withDuration: 0.25) {
      [unowned self] in

      self.loopToggleButton.isHidden = true
      self.loopToolButtons.forEach {
        $0.isHidden = false
        $0.setNeedsDisplay()
      }
      self.loopToolsWidthConstraint.constant = 4 * self.buttonWidth + 3 * self.buttonPadding
    }

  }

  private func didExitLoopMode(_ notification: Notification) {

    UIView.animate(withDuration: 0.25) {
      [unowned self] in

      self.loopToggleButton.isHidden = false
      self.loopToggleButton.setNeedsDisplay()
      self.loopToolButtons.forEach { $0.isHidden = true }
      self.loopToolsWidthConstraint.constant = self.buttonWidth
    }

  }


  private func initializeReceptionist() {

    guard receptionist.count == 0 else { return }

    receptionist.observe(name: .didChangeDocument, from: DocumentManager.self,
                         callback: weakMethod(self, MIDINodePlayerViewController.didChangeDocument))
    receptionist.observe(name: .willOpenDocument, from: DocumentManager.self,
                         callback: weakMethod(self, MIDINodePlayerViewController.willOpenDocument))
    receptionist.observe(name: .didSelectTool, from: MIDINodePlayer.self,
                         callback: weakMethod(self, MIDINodePlayerViewController.didSelectTool))
    receptionist.observe(name: .didEnterLoopMode, from: Sequencer.self,
                         callback: weakMethod(self, MIDINodePlayerViewController.didEnterLoopMode))
    receptionist.observe(name: .didExitLoopMode, from: Sequencer.self,
                         callback: weakMethod(self, MIDINodePlayerViewController.didExitLoopMode))

  }

}

extension MIDINodePlayerViewController: UITextFieldDelegate {

  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return DocumentManager.currentDocument != nil
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return false
  }

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

  func textFieldDidEndEditing(_ textField: UITextField) {
    guard
      let text = textField.text,
      DocumentManager.currentDocument?.localizedName != text
      else
    {
      return
    }

    DocumentManager.currentDocument?.rename(to: text)
  }

}
