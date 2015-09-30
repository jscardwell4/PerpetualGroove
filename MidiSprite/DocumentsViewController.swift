//
//  DocumentsViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 10/24/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Eveleth

final class DocumentsViewController: UIViewController {

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var stackViewHeightConstraint: NSLayoutConstraint!

  var selectFile: ((NSMetadataItem) -> Void)?
  var deleteFile: ((NSMetadataItem) -> Void)?

  private let constraintID = Identifier("DocumentsViewController", "Internal")

  private var notificationReceptionist: NotificationReceptionist!

  /** setup */
  private func setup() {
    guard case .None = notificationReceptionist else { return }
    notificationReceptionist = NotificationReceptionist(callbacks:[
      MIDIDocumentManager.Notification.DidUpdateMetadataItems.rawValue:
        (MIDIDocumentManager.self, NSOperationQueue.mainQueue(), didUpdateItems)
      ])
  }

  /**
  didUpdateFileURLs:

  - parameter notification: NSNotification
  */
  private func didUpdateItems(notification: NSNotification) { items = MIDIDocumentManager.metadataItems }

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

  private var items: [NSMetadataItem] = [] {
    didSet {
      maxLabelSize = items.reduce(.zero) {
        [attributes = [NSFontAttributeName:UIFont.controlFont], unowned self] size, item in

        let displayNameSize = item.displayName?.sizeWithAttributes(attributes) ?? .zero
        return CGSize(width: max(size.width, displayNameSize.width + 10), height: self.labelHeight)
      }
      updateLabelButtons()
    }
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) { items = MIDIDocumentManager.metadataItems }

  /**
  labelButtonAction:

  - parameter sender: LabelButton
  */
  @IBAction private func labelButtonAction(sender: LabelButton) {
    guard items.indices.contains(sender.tag) else { return }
    selectFile?(items[sender.tag])
  }

  /**
  applyText:views:

  - parameter urls: S1
  - parameter views: S2
  */
  private func applyText<S1:SequenceType, S2:SequenceType
    where S1.Generator.Element == NSMetadataItem,
          S2.Generator.Element == UIView>(urls: S1, _ views: S2)
  {
    zip(urls, views).forEach {
      guard let displayName = $0.displayName, label = $1 as? LabelButton else { return }
      label.text = displayName
    }
  }

  /** updateLabelButtons */
  private func updateLabelButtons() {
    (stackView.arrangedSubviews.count ..< stackView.subviews.count).forEach {
      let subview = stackView.subviews[$0]
      subview.hidden = false
      stackView.addArrangedSubview(subview)
    }
    switch (items.count, stackView.arrangedSubviews.count) {
      case let (itemCount, arrangedCount) where itemCount == arrangedCount:
        applyText(items, stackView.arrangedSubviews)

      case let (itemCount, arrangedCount) where arrangedCount > itemCount:
        stackView.arrangedSubviews[itemCount ..< arrangedCount].forEach {
          stackView.removeArrangedSubview($0)
          $0.hidden = true
        }
        applyText(items, stackView.arrangedSubviews)

      case let (itemCount, arrangedCount) where itemCount > arrangedCount:
        (arrangedCount ..< itemCount).forEach { stackView.addArrangedSubview(newLabelButtonWithTag($0)) }
        applyText(items, stackView.arrangedSubviews)

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
      view.constrain([view.width ≥ contentSize.width, view.height ≥ contentSize.height] --> constraintID)
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
      let pad = view.layoutMargins.displacement
      contentSize = CGSize(width: max(maxLabelSize.width + pad.horizontal, 240),
                           height: max(maxLabelSize.height * CGFloat(items.count) + pad.vertical, 108))
    }
  }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }

}
