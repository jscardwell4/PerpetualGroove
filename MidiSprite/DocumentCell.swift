//
//  DocumentCell.swift
//  MidiSprite
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
    logDebug()
  }

  var showingDelete: Bool { return leadingConstraint.constant < 0 }

  var item: DocumentItemType? { didSet { label.text = item?.displayName } }

  /**
  animationDurationForDistance:

  - parameter distance: CGFloat

  - returns: NSTimeInterval
  */
  private func animationDurationForDistance(distance: CGFloat) -> NSTimeInterval {
    return NSTimeInterval(CGFloat(0.25) * distance / self.deleteButton.bounds.size.width)
  }

  /**
  revealDelete:

  - parameter distance: CGFloat
  */
  func revealDelete(distance: CGFloat? = nil) {
    UIView.animateWithDuration(animationDurationForDistance(distance ?? deleteButton.bounds.width),
                    animations: { self.leadingConstraint.constant = -self.deleteButton.bounds.width },
                    completion: nil)
  }

  /**
  hideDelete:

  - parameter distance: CGFloat
  */
  func hideDelete(distance: CGFloat? = nil) {
    UIView.animateWithDuration(animationDurationForDistance(distance ?? deleteButton.bounds.width),
                    animations: { self.leadingConstraint.constant = 0 },
                    completion: nil)
  }

  /** setup */
  private func setup() {
    var previousState: UIGestureRecognizerState = .Possible
    let gesture = PanGesture(handler: {
      [unowned self] in

      let pan = $0 as! PanGesture

      let x = pan.translationInView(self).x

      switch pan.state {

        case .Began, .Changed:
          guard x < 0 else { break }
          self.leadingConstraint.constant = x

        case .Ended:
          guard previousState == .Changed else { break }
          (x <= -self.deleteButton.bounds.width ? self.revealDelete : self.hideDelete)(abs(x))

        case .Cancelled, .Failed:
          self.hideDelete(abs(x))

        default: break

      }

      previousState = pan.state

      })

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