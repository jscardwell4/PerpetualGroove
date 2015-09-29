//
//  FilesViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 10/24/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Eveleth

final class FilesViewController: UIViewController {

  @IBOutlet weak var scrollView: UIScrollView!

  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var stackViewHeightConstraint: NSLayoutConstraint!

  var didSelectFile: ((NSURL) -> Void)?
  var didDeleteFile: ((NSURL) -> Void)?

  private let constraintID = Identifier("FilesViewController", "Internal")

//  private lazy var directoryMonitor: DirectoryMonitor = {
//    do {
//      return try DirectoryMonitor(directoryURL: documentsURL) { [unowned self] _ in self.refreshFiles() }
//    } catch { logError(error); fatalError("failed to create monitor for documents directory: \(error)") }
//  }()

  private var notificationReceptionist: NotificationReceptionist!

  /** setup */
  private func setup() {
    guard case .None = notificationReceptionist else { return }
    notificationReceptionist = NotificationReceptionist(callbacks:[
      MIDIDocumentManager.Notification.DidUpdateFileURLs.rawValue:
        (MIDIDocumentManager.self, NSOperationQueue.mainQueue(),didUpdateFileURLs)
      ])
  }

  /**
  didUpdateFileURLs:

  - parameter notification: NSNotification
  */
  private func didUpdateFileURLs(notification: NSNotification) { files = MIDIDocumentManager.fileURLs }

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

  private var files: [NSURL] = [] {
    didSet {
      maxLabelSize = files.reduce(.zero) {
        [attributes = [NSFontAttributeName:UIFont.controlFont], unowned self] size, url in

        let urlSize = url.lastPathComponent!.sizeWithAttributes(attributes)
        return CGSize(width: max(size.width, urlSize.width + 10), height: self.labelHeight)
      }
      updateLabelButtons()
    }
  }

  /** viewDidLoad */
//  override func viewDidLoad() {
//    super.viewDidLoad()
//    view.translatesAutoresizingMaskIntoConstraints = false
//    refreshFiles()
//  }

  /**
  labelButtonAction:

  - parameter sender: LabelButton
  */
  @IBAction private func labelButtonAction(sender: LabelButton) {
    guard files.indices.contains(sender.tag) else { return }
    didSelectFile?(files[sender.tag])
  }

  /**
  applyText:views:

  - parameter urls: S1
  - parameter views: S2
  */
  private func applyText<S1:SequenceType, S2:SequenceType
    where S1.Generator.Element == NSURL,
          S2.Generator.Element == UIView>(urls: S1, _ views: S2)
  {
    zip(urls, views).forEach {
      guard let fileName = $0.lastPathComponent, label = $1 as? LabelButton else { return }
      label.text = fileName[..<fileName.endIndex.advancedBy(-4)]
    }
  }

  /** updateLabelButtons */
  private func updateLabelButtons() {
    (stackView.arrangedSubviews.count ..< stackView.subviews.count).forEach {
      let subview = stackView.subviews[$0]
      subview.hidden = false
      stackView.addArrangedSubview(subview)
    }
    switch (files.count, stackView.arrangedSubviews.count) {
      case let (fileCount, arrangedCount) where fileCount == arrangedCount:
        applyText(files, stackView.arrangedSubviews)

      case let (fileCount, arrangedCount) where arrangedCount > fileCount:
        stackView.arrangedSubviews[fileCount ..< arrangedCount].forEach {
          stackView.removeArrangedSubview($0)
          $0.hidden = true
        }
        applyText(files, stackView.arrangedSubviews)

      case let (fileCount, arrangedCount) where fileCount > arrangedCount:
        (arrangedCount ..< fileCount).forEach { stackView.addArrangedSubview(newLabelButtonWithTag($0)) }
        applyText(files, stackView.arrangedSubviews)

      default: break // Unreachable
    }
  }

  private let labelHeight: CGFloat = 32

  /**
  newLabelButtonWithText:

  - parameter text: String

  - returns: LabelButton
  */
  private func newLabelButtonWithTag(tag: Int) -> LabelButton {
    let labelButton = LabelButton(autolayout: true)
    labelButton.font = .labelFont
    labelButton.textColor = .primaryColor
    labelButton.highlightedTextColor = .highlightColor
    labelButton.tag = tag
    labelButton.tag = stackView.subviews.count
    labelButton.addTarget(self, action: "labelButtonAction:", forControlEvents: .TouchUpInside)
    return labelButton
  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    if view.constraintsWithIdentifier(constraintID).count == 0 {
      view.constrain([view.width ≥ max(contentSize.width, 240), view.height ≥ max(contentSize.height, 108)] --> constraintID)
    }
    super.updateViewConstraints()
  }

  private var contentSize: CGSize = .zero {
    didSet {
      scrollView.contentSize = contentSize
      stackViewHeightConstraint.constant = contentSize.height
      if view.constraintsWithIdentifier(constraintID).count > 0 {
        view.removeConstraints(view.constraintsWithIdentifier(constraintID))
        view.setNeedsUpdateConstraints()
      }
    }
  }
  private var maxLabelSize: CGSize = .zero {
    didSet {
      contentSize = CGSize(width: max(maxLabelSize.width, 100), height: max(maxLabelSize.height * CGFloat(files.count), 44))
    }
  }

  /** refreshFiles */
//  private func refreshFiles() {
//    do { files = try documentsDirectoryContents().filter {$0.pathExtension == "mid" } } catch { logError(error) }
//  }

  private var tableWidth: CGFloat { return maxLabelSize.width }
  private var tableHeight: CGFloat { return maxLabelSize.height * CGFloat(files.count) }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
//  override func viewWillAppear(animated: Bool) {
//    super.viewWillAppear(animated)
//    refreshFiles()
//    directoryMonitor.startMonitoring()
//  }

  /**
  viewWillDisappear:

  - parameter animated: Bool
  */
//  override func viewWillDisappear(animated: Bool) {
//    super.viewWillDisappear(animated)
//    directoryMonitor.stopMonitoring()
//  }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }

}
