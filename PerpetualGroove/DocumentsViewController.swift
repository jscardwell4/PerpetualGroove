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

    receptionist.observe(notification: .DidUpdateItems,
                         from: DocumentManager.self,
                         callback: weakMethod(self, DocumentsViewController.didUpdateItems))

    receptionist.observe(notification: .DidChangeDocument, from: DocumentManager.self) {
      [weak self] _ in self?.refreshSelection()
    }
  }

  // MARK: - Document items

  private var selectedItem: NSIndexPath? {
    didSet {
      guard isViewLoaded() else { return }
      if oldValue != selectedItem {
        logDebug("\(oldValue?.description ?? "nil") ➞ \(selectedItem?.description ?? "nil")")
      }
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

  /// Returns the index path for a document; returns nil if document is not represented in the collection
  private func indexPathForDocument(document: Document) -> NSIndexPath? {
    guard let idx = items.indexOf({$0.URL.isEqualToFileURL(document.fileURL)}) else {
      return nil
    }
    return NSIndexPath(forItem: idx, inSection: 1)
  }

  /** refreshSelection */
  private func refreshSelection() {
    guard isViewLoaded() else { return }
    guard let document = DocumentManager.currentDocument else { selectedItem = nil; return }

    switch indexPathForDocument(document) {
      case let indexPath?:
        selectedItem = indexPath
      default:
        let indexPath = NSIndexPath(forItem: items.count, inSection: 1)
        let item = DocumentItem(document)
        items.append(item)
        collectionView?.performBatchUpdates({ 
          [unowned self] in
          self.collectionView?.insertItemsAtIndexPaths([indexPath])
          }, completion: {
            [unowned self] completed in
            guard completed else { return }
            self.selectedItem = indexPath
          })
    }
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
    (collectionViewLayout as? DocumentsViewLayout)?.controller = self
    guard !DocumentManager.gatheringMetadataItems else { return }
    items = OrderedSet(DocumentManager.items)
    refreshSelection()
  }

  /// Adds constraints for `collectionView` when needed and updates content width and height constraints
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

  /// Adds `items` to the controller's `items` and adds cells to the collection view
  private func addItems(items: [DocumentItem]) {
    let oldCount = self.items.count
    self.items ∪= items
    let newCount = self.items.count
    let added = (oldCount ..< newCount).map { NSIndexPath(forItem: $0, inSection: 1) }
    logDebug("adding items at indices \(added)")
    if !added.isEmpty { collectionView?.insertItemsAtIndexPaths(added) }
  }

  /// Removes `items` from the controller's `items` and deletes the cells from the collection view
  private func removeItems(items: [DocumentItem]) {
    let removed: [NSIndexPath] = items.flatMap {
      guard let idx = self.items.indexOf($0) else { return nil }
      return NSIndexPath(forItem: idx, inSection: 1)
    }
    self.items ∖= items
    if !removed.isEmpty { collectionView?.deleteItemsAtIndexPaths(removed) }
  }


  /// Adds and/or removes items according to the contents of `notification`
  private func didUpdateItems(notification: NSNotification) {
    guard isViewLoaded() else { return }

    collectionView?.performBatchUpdates({
      [unowned self] in
        switch (notification.addedItems, notification.removedItems) {
          case let (addedItems?, removedItems?): self.addItems(addedItems); self.removeItems(removedItems)
          case let (nil, removedItems?):         self.removeItems(removedItems)
          case let (addedItems?, nil):           self.addItems(addedItems)
          case (nil, nil):                       break
        }
      }, completion: {[unowned self] completed in guard completed else { return }; self.refreshSelection() })
  }

  // MARK: UICollectionViewDataSource

  /// Returns two: one for the create item and one for the existing document items
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 2 }

  /// Returns the number of existing documents when section == 1 and one otherwise
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return section == 1 ? items.count : 1
  }

  /// Returns an instance of `CreateDocumentCell` when section == 0 and an instance of `DocumentCell` otherwise
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

  /// Returns `true` unless the cell is showing its delete button
  override func     collectionView(collectionView: UICollectionView,
    shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
  {
    guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? DocumentCell
      where cell.showingDelete else { return true }
    cell.hideDelete()
    return false
  }

  /// Creates a new document when section == 0; opens the document otherwise
  override func collectionView(collectionView: UICollectionView,
      didSelectItemAtIndexPath indexPath: NSIndexPath)
  {
    switch indexPath.section {
      case 0:  DocumentManager.createNewDocument()
      default: DocumentManager.openItem(items[indexPath.row])
    }
    dismiss?()
  }
}
