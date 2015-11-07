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

  // MARK: - Properties

  var dismiss: (() -> Void)?

  private let constraintID = Identifier("DocumentsViewController", "CollectionView")

  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  @IBOutlet weak var documentsViewLayout: DocumentsViewLayout! { didSet { documentsViewLayout.controller = self } }

  private(set) var itemSize: CGSize = .zero {
    didSet {
      let (w, h) = itemSize.unpack
      collectionViewSize = CGSize(width: w, height: h * CGFloat(items.count + 1))
    }
  }

  private var collectionViewSize: CGSize = .zero {
    didSet {
      guard collectionViewSize != oldValue else { return }
      switch (widthConstraint, heightConstraint) {
        case let (widthConstraint?, heightConstraint?):
          let (w, h) = collectionViewSize.unpack
          widthConstraint.constant = w
          heightConstraint.constant = h
        default:
          view?.setNeedsUpdateConstraints()
      }
      collectionViewLayout.invalidateLayout()
   }
  }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }

  // MARK: - Initialization

  /** setup */
  override func awakeFromNib() {

    super.awakeFromNib()

    (collectionViewLayout as? DocumentsViewLayout)?.controller = self

    receptionist.observe(MIDIDocumentManager.Notification.DidUpdateItems,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, DocumentsViewController.didUpdateItems))

    receptionist.observe(MIDIDocumentManager.Notification.DidCreateDocument,
                   from: MIDIDocumentManager.self,
               callback: weakMethod(self, DocumentsViewController.didCreateDocument))

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, DocumentsViewController.didChangeDocument))
  }

  // MARK: - Document items

//  private var selectedItemURL: NSURL? {
//    didSet {
//      guard let url = selectedItemURL, idx = items.indexOf({$0.URL == url}) else { selectedItem = nil; return }
//      selectedItem = NSIndexPath(forItem: idx, inSection: 1)
//    }
//  }

  private var selectedItem: NSIndexPath? {
    didSet {
      guard isViewLoaded() else { return }
      collectionView?.selectItemAtIndexPath(selectedItem, animated: true, scrollPosition: .CenteredVertically)
    }
  }

  private var items: [DocumentItem] = [] {
    didSet {
      updateItemSize()
      collectionView?.reloadData()
      logDebug("items updated and data reloaded")
    }
  }

  /** updateItemSize */
  private func updateItemSize() {
    let font = UIFont.controlFont
    let characterCount = max(CGFloat(items.map({$0.displayName.characters.count ?? 0}).maxElement() ?? 0), 15)
    itemSize = CGSize(width: characterCount * font.characterWidth, height: font.pointSize * 2).integralSize
  }

  // MARK: - View lifecycle

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView?.translatesAutoresizingMaskIntoConstraints = false
    view.translatesAutoresizingMaskIntoConstraints = false
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {
    guard !MIDIDocumentManager.gatheringMetadataItems else { return }
    items = MIDIDocumentManager.items
  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    guard let collectionView = collectionView else { super.updateViewConstraints(); return }

    if view.constraintsWithIdentifier(constraintID).count == 0 {
      view.constrain([𝗩|-collectionView-|𝗩, 𝗛|-collectionView-|𝗛] --> constraintID)
    }

    guard case (.None, .None) = (widthConstraint, heightConstraint) else { super.updateViewConstraints(); return }

    let (w, h) = collectionViewSize.unpack
    widthConstraint = (collectionView.width => w --> Identifier(self, "Content", "Width")).constraint
    widthConstraint?.active = true
    heightConstraint = (collectionView.height => h --> Identifier(self, "Content", "Height")).constraint
    heightConstraint?.active = true

    super.updateViewConstraints()
  }

  // MARK: - Notifications

  /**
  didChangeDocument:

  - parameter notification: NSNotification
  */
  private func didChangeDocument(notification: NSNotification) {
    logDebug("")
  }

  /**
  didCreateDocument:

  - parameter notification: NSNotification
  */
  private func didCreateDocument(notification: NSNotification) {
    logDebug("")
  }

  /**
  didUpdateItems:

  - parameter notification: NSNotification? = nil
  */
  private func didUpdateItems(notification: NSNotification) {
    guard isViewLoaded() else { return }
    var items = self.items
    if let addedItems = notification.addedItems {
      logDebug("addedItems: \(addedItems)")
      items += addedItems
    }
    if let removedItems = notification.removedItems {
      logDebug("removedItems: \(removedItems)")
      items ∖= removedItems
    }
    self.items = items
  }

  // MARK: UICollectionViewDataSource

  /**
  numberOfSectionsInCollectionView:

  - parameter collectionView: UICollectionView

  - returns: Int
  */
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 2 }

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
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(CreateDocumentCell.Identifier,
                                                        forIndexPath: indexPath)
      default:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(DocumentCell.Identifier,
                                                        forIndexPath: indexPath)
        (cell as? DocumentCell)?.item = items[indexPath.row]
    }
    
    return cell
  }

  // MARK: - UICollectionViewDelegate

  /**
  collectionView:shouldHighlightItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: Bool
  */
  override func     collectionView(collectionView: UICollectionView,
    shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
  {
    guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? DocumentCell where cell.showingDelete else { return true }
    cell.hideDelete()
    return false
  }

  /**
  collectionView:didSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    switch indexPath.section {
      case 0:  MIDIDocumentManager.createNewDocument()
      default: MIDIDocumentManager.openItem(items[indexPath.row])
    }
    dismiss?()
  }
}
