//
//  DocumentCell.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class DocumentCell: UICollectionViewCell {
  static let Identifier = "DocumentCell"

  @IBOutlet var deleteButton: LabelButton!
  @IBOutlet var label: UILabel!
  @IBOutlet var leadingConstraint: NSLayoutConstraint!

  /** deleteItem */
  @IBAction func deleteItem() {
    guard let item = item else { return }
    if SettingsManager.confirmDeleteDocument { logWarning("delete confirmation not yet implemented") }
    MIDIDocumentManager.deleteItem(item)
  }

  private(set) var showingDelete: Bool = false

  var item: DocumentItem? { didSet { refresh() } }

  /** refresh */
  func refresh() { label.text = item?.displayName }

  /**
  animationDurationForDistance:

  - parameter distance: CGFloat

  - returns: NSTimeInterval
  */
  private func animationDurationForDistance(distance: CGFloat?) -> NSTimeInterval {
    guard let distance = distance else { return 0.25 }
    return NSTimeInterval(CGFloat(0.25) * distance / deleteButton.bounds.width)
  }

  /**
  revealDelete:

  - parameter distance: CGFloat
  */
  func revealDelete(distance: CGFloat? = nil) {
    UIView.animateWithDuration(animationDurationForDistance(distance),
                    animations: { self.leadingConstraint.constant = -self.deleteButton.bounds.width },
                    completion: {self.showingDelete = $0})
  }

  /**
  hideDelete:

  - parameter distance: CGFloat
  */
  func hideDelete(distance: CGFloat? = nil) {
    UIView.animateWithDuration(animationDurationForDistance(distance),
                    animations: { self.leadingConstraint.constant = 0 },
                    completion: {self.showingDelete = !$0})
  }

  /**
  handlePan:

  - parameter gesture: PanGesture
  */
  private func handlePan(gesture: BlockActionGesture) {
    guard let pan = gesture as? PanGesture else { return }

    let x = pan.translationInView(self).x

    switch (pan.state, showingDelete) {

      case (.Began, false) where x < 0, (.Changed, false) where x < 0:
        leadingConstraint.constant = x

      case (.Began, true) where x > 0, (.Changed, true) where x > 0:
        leadingConstraint.constant = -deleteButton.bounds.width + x

      case (.Ended, false) where x <= -deleteButton.bounds.width:
        revealDelete(abs(x))

      case (.Ended, _), (.Cancelled, _), (.Failed, _):
        hideDelete(abs(x))

      default: break

    }

  }

  /** setup */
  private func setup() {
    let gesture = PanGesture(handler: unownedMethod(self, DocumentCell.handlePan))
    gesture.confineToView = true
    gesture.delaysTouchesBegan = true
    gesture.axis = .Horizontal
    addGestureRecognizer(gesture)
  }

  /** prepareForReuse */
  override func prepareForReuse() {
    super.prepareForReuse()
    if showingDelete { hideDelete() }
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

}

final class CreateDocumentCell: UICollectionViewCell {
  static let Identifier = "CreateDocumentCell"
}