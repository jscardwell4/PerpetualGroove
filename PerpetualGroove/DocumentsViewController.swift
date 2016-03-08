//
//  DocumentsViewController.swift
//  PerpetualGroove
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

  weak var documentsViewLayout: DocumentsViewLayout! { didSet { documentsViewLayout.controller = self } }

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

    receptionist.observe(.DidUpdateItems,
                    from: MIDIDocumentManager.self,
                callback: weakMethod(self, DocumentsViewController.didUpdateItems))

    receptionist.observe(.DidCreateDocument, from: MIDIDocumentManager.self) {
      [weak self] notification in self?.logDebug("\(notification)")
    }

    receptionist.observe(.DidChangeDocument, from: MIDIDocumentManager.self) {
      [weak self] _ in self?.refreshSelection()
    }
  }

  // MARK: - Document items

  private var selectedItem: NSIndexPath? {
    didSet {
      guard isViewLoaded() else { return }
      if oldValue != selectedItem { logDebug("\(oldValue?.description ?? "nil") ➞ \(selectedItem?.description ?? "nil")") }
      collectionView?.selectItemAtIndexPath(selectedItem, animated: true, scrollPosition: .CenteredVertically)
    }
  }

  private var items: OrderedSet<DocumentItem> = [] {
    didSet {
      let font = UIFont.controlFont
      let characterCount = max(CGFloat(items.map({$0.displayName.characters.count ?? 0}).maxElement() ?? 0), 15)
      let width = characterCount * font.characterWidth
      let height = font.pointSize * 2
      let size = CGSize(width: width, height: height)
      itemSize = size.integralSize
      mainQueue.async {
        [weak self] in
        self?.collectionView?.reloadData()
        self?.refreshSelection()
      }
    }
  }

  /** refreshSelection */
  private func refreshSelection() {
    guard isViewLoaded() else { return }
    guard let document = MIDIDocumentManager.currentDocument else { selectedItem = nil; return }

    guard let idx = items.indexOf({$0.URL == document.fileURL}) else {
        fatalError("document not found in items: \(document)")
    }
    selectedItem = NSIndexPath(forItem: idx, inSection: 1)
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
    items = OrderedSet(MIDIDocumentManager.items)
    refreshSelection()
  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    guard let collectionView = collectionView else { super.updateViewConstraints(); return }

    if view.constraintsWithIdentifier(constraintID).count == 0 {
      view.constrain([𝗩|--collectionView--|𝗩, 𝗛|--collectionView--|𝗛] --> constraintID)
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

  private func addItems(items: [DocumentItem]) -> [NSIndexPath] {
    let oldCount = self.items.count
    self.items ∪= items
    let newCount = self.items.count
    return (oldCount ..< newCount).map { NSIndexPath(forItem: $0, inSection: 1) }
  }

  private func removeItems(items: [DocumentItem]) -> [NSIndexPath] {
    let indexPaths: [NSIndexPath] = items.flatMap {
      guard let idx = self.items.indexOf($0) else { return nil }
      return NSIndexPath(forItem: idx, inSection: 1)
    }
    self.items ∖= items
    return indexPaths
  }


  /**
  didUpdateItems:

  - parameter notification: NSNotification? = nil
  */
  private func didUpdateItems(notification: NSNotification) {
    guard isViewLoaded() else { return }

    collectionView?.performBatchUpdates({
      [unowned self] in
        switch (notification.addedItems, notification.removedItems) {
          case let (addedItems?, removedItems?) where !(addedItems.isEmpty && removedItems.isEmpty):
            let added = self.addItems(addedItems)
            self.logDebug("adding items at indices \(added)")
            let removed = self.removeItems(removedItems)
            self.logDebug("removing items at indices \(removed)")

            if !removed.isEmpty { self.collectionView?.deleteItemsAtIndexPaths(removed) }
            if !added.isEmpty { self.collectionView?.insertItemsAtIndexPaths(added) }

          case let (nil, removedItems?) where !removedItems.isEmpty:
            let removed = self.removeItems(removedItems)
            guard !removed.isEmpty else { return }
            self.logDebug("removing items at indices \(removed)")
            self.collectionView?.deleteItemsAtIndexPaths(removed)

          case let (addedItems?, nil) where !addedItems.isEmpty:
            let added = self.addItems(addedItems)
            guard !added.isEmpty else { break }
            self.logDebug("adding items at indices \(added)")
            self.collectionView?.insertItemsAtIndexPaths(added)

          default: break
        }
      }, completion: {[unowned self] completed in guard completed else { return }; self.refreshSelection() })
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
      case 1:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(DocumentCell.Identifier,
                                                        forIndexPath: indexPath)
        (cell as! DocumentCell).item = items[indexPath.item]
      default:
        fatalError("Invalid section")
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
    guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? DocumentCell
      where cell.showingDelete else { return true }
    cell.hideDelete()
    return false
  }

  /**
  collectionView:didSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView,
      didSelectItemAtIndexPath indexPath: NSIndexPath)
  {
    switch indexPath.section {
      case 0:  MIDIDocumentManager.createNewDocument()
      default: MIDIDocumentManager.openItem(items[indexPath.row])
    }
    dismiss?()
  }
}
