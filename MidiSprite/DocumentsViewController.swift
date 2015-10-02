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

final class DocumentsViewController: UICollectionViewController {

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
  init:

  - parameter layout: UICollectionViewLayout
  */
  override init(collectionViewLayout layout: UICollectionViewLayout) {
    super.init(collectionViewLayout: layout)
    setup()
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
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }

  private var items: [NSMetadataItem] = [] {
    didSet {
      maxLabelSize = items.reduce(.zero) {
        [attributes = [NSFontAttributeName:UIFont.controlFont]] size, item in

        let displayNameSize = item.displayName?.sizeWithAttributes(attributes) ?? .zero
        return CGSize(width: max(size.width, displayNameSize.width + 10), height: max(size.height, displayNameSize.height))
      }
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

  private let labelHeight: CGFloat = 32

  /** updateViewConstraints */
  override func updateViewConstraints() {
    if view.constraintsWithIdentifier(constraintID).count == 0 {
      view.constrain([view.width ≥ contentSize.width, view.height ≥ contentSize.height] --> constraintID)
    }
    super.updateViewConstraints()
  }

  private var contentSize: CGSize = .zero {
    didSet {
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

  // MARK: UICollectionViewDataSource

  /**
  numberOfSectionsInCollectionView:

  - parameter collectionView: UICollectionView

  - returns: Int
  */
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 3 }

  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return section == 1 ? items.count : 1
  }

  /**
  collectionView:cellForItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewCell
  */
  override func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
  {
    let cell: UICollectionViewCell
    switch indexPath.section {
      case 0:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(CreateDocumentCell.Identifier, forIndexPath: indexPath)
      default:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(DocumentCell.Identifier, forIndexPath: indexPath)
        (cell as? DocumentCell)?.item = items[indexPath.row]
    }
    
    return cell
  }

}
