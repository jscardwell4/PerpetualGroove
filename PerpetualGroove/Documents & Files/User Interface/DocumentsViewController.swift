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

// FIXME: Deleting the current document halts application
final class DocumentsViewController: UICollectionViewController {

  // MARK: - Properties

  var dismiss: (() -> Void)?

  /// Removes an item from the collection, deleting the corresponding document 
  @IBAction func deleteItem(_ sender: LabelButton) {

    guard let item = (sender.superview?.superview as? DocumentCell)?.item else {
      Log.warning("sender superview is not an item-containing document cell")
      return
    }

    guard let indexPath = indexPathForItem(item) else {
      Log.warning("items does not contain item to delete: \(item)")
      return
    }

    if SettingsManager.confirmDeleteDocument {
      Log.warning("delete confirmation not yet implemented")
    }

    if selectedItem == indexPath { selectedItem = nil }

    items.remove(item)

    collectionView?.performBatchUpdates(
      {
        [unowned self] in
        self.collectionView?.deleteItems(at: [indexPath])
      },
      completion: {
        [unowned self] completed in

        guard completed else {
          self.items.insert(item, at: indexPath.item)
          return
        }

        DocumentManager.delete(item: item)
      }
    )

  }

  /// Identifier used with constraints binding the edges of the collection view
  private let constraintID = Identifier("DocumentsViewController", "CollectionView")

  /// Constraint for the collection view's width
  private var widthConstraint: NSLayoutConstraint?

  /// Constraint for the collection view's height
  private var heightConstraint: NSLayoutConstraint?

  /// Receptionist for observing notifications from `DocumentManager`
  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  /// Necssary size for displaying an item in the collection
  private(set) var itemSize: CGSize = .zero {
    didSet {
      let (w, h) = itemSize.unpack
      collectionViewSize = CGSize(width: w, height: h * CGFloat(items.count + 1))
    }
  }

  /// Necessary size for displaying the current collection of items
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

  override var prefersStatusBarHidden : Bool { return true }

  // MARK: - Initialization

  /// Adds observations for `DocumentManager` notifications
  override func awakeFromNib() {

    super.awakeFromNib()

    receptionist.observe(name: .didUpdateItems, from: DocumentManager.self,
                         callback: weakMethod(self, DocumentsViewController.didUpdateItems))

    receptionist.observe(name: .willChangeDocument, from: DocumentManager.self,
                         callback: weakMethod(self, DocumentsViewController.willChangeDocument))

    receptionist.observe(name: .didChangeDocument, from: DocumentManager.self,
                         callback: weakMethod(self, DocumentsViewController.didChangeDocument))

    guard let currentDocument = DocumentManager.currentDocument else { return }
    receptionist.observe(name: .didRenameDocument, from: currentDocument,
                         callback: weakMethod(self, DocumentsViewController.documentDidChangeName))
  }

  // MARK: - Document items

  /// The currently selected document item; should always represent `DocumentManager.currentDocument`
  private var selectedItem: IndexPath? {
    didSet {
      guard isViewLoaded else { return }
      if oldValue != selectedItem {
        Log.debug("\(oldValue?.description ?? "nil") ➞ \(selectedItem?.description ?? "nil")")
      }
      collectionView?.selectItem(at: selectedItem, animated: true, scrollPosition: .centeredVertically)
    }
  }

  /// Reloads `collectionView` and refreshes selection
  private func reloadData() {
    DispatchQueue.main.async {
      [weak self] in

      self?.collectionView?.reloadData()
      self?.refreshSelection()
    }
  }

  /// Returns the minimum width for a cell displaying `item`
  private func cellWidthForItem(_ item: DocumentItem) -> CGFloat {
    let characterCount = CGFloat(max(item.displayName.characters.count, 15))
    let characterWidth = UIFont.controlFont.characterWidth
    return characterCount * characterWidth
  }

  /// Set of document items used to populate the collection
  private var items: OrderedSet<DocumentItem> = [] {
    didSet {
      let width = items.map({cellWidthForItem($0)}).max() ?? 0
      let height = UIFont.controlFont.pointSize * 2
      let size = CGSize(width: width, height: height)
      itemSize = size.integralSize
    }
  }

  /// Returns the index path for a document item or nil if `items` does not contain `item`.
  private func indexPathForItem(_ item: DocumentItem) -> IndexPath? {
    guard let idx = items.index(of: item) else { return nil }
    return IndexPath(item: idx, section: 1)
  }

  /// Returns the index path for a document; returns nil if document is not represented in the collection.
  private func indexPathForDocument(_ document: Document) -> IndexPath? {
    guard let idx = items.index(where: {$0.url.isEqualToFileURL(document.fileURL)}) else {
      return nil
    }
    return IndexPath(item: idx, section: 1)
  }

  /// Uses the value in `DocumentManager.currentDocument` to locate the corresponding element in `items`,
  /// setting `selectedItem` to its equivalent index path. If the collection does not contain such an item,
  /// It is created, a new cell is added to the collection view, and then `selectedItem` updated.
  private func refreshSelection() {
    guard isViewLoaded else { return }
    guard let document = DocumentManager.currentDocument else { selectedItem = nil; return }

    switch indexPathForDocument(document) {
      case let indexPath?:
        selectedItem = indexPath
      default:
        let indexPath = IndexPath(item: items.count, section: 1)
        items.append(.document(document))
        collectionView?.performBatchUpdates(
          {
            [unowned self] in
            self.collectionView?.insertItems(at: [indexPath])
          },
          completion: {
            [unowned self] completed in

            guard completed else { return }
            self.selectedItem = indexPath
          }
      )
    }
  }

  // MARK: - View lifecycle

  /// Disables autoresizing mask constraints
  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView?.translatesAutoresizingMaskIntoConstraints = false
    view.translatesAutoresizingMaskIntoConstraints = false
  }

  /// Updates the contents of `items` and refreshes the current selection
  override func viewWillAppear(_ animated: Bool) {
    (collectionViewLayout as? DocumentsViewLayout)?.controller = self
    guard !DocumentManager.gatheringMetadataItems else { return }
    items = OrderedSet(DocumentManager.items)
    reloadData()
  }

  /// Adds constraints for `collectionView` when needed and updates content width and height constraints
  override func updateViewConstraints() {
    guard let collectionView = collectionView else { super.updateViewConstraints(); return }

    if view.constraintsWithIdentifier(constraintID).count == 0 {
      view.constrain([𝗩|--collectionView--|𝗩, 𝗛|--collectionView--|𝗛] --> constraintID)
    }

    guard case (.none, .none) = (widthConstraint, heightConstraint) else { super.updateViewConstraints(); return }

    let (w, h) = collectionViewSize.unpack
    widthConstraint = (collectionView.width => w --> Identifier(self, "Content", "Width")).constraint
    widthConstraint?.isActive = true
    heightConstraint = (collectionView.height => h --> Identifier(self, "Content", "Height")).constraint
    heightConstraint?.isActive = true

    super.updateViewConstraints()
  }

  // MARK: - Notifications

  /// Adds `items` to the controller's `items` and adds cells to the collection view
  private func addItems(_ newItems: [DocumentItem]) {
    let oldCount = items.count
    items ∪= newItems
    let newCount = items.count
    let added = (oldCount ..< newCount).map { IndexPath(item: $0, section: 1) }
    Log.debug("adding items at indices \(added)")
    if !added.isEmpty { collectionView?.insertItems(at: added) }
  }

  /// Removes `items` from the controller's `items` and deletes the cells from the collection view
  private func removeItems(_ items: [DocumentItem]) {
    let removed: [IndexPath] = items.flatMap {
      guard let idx = self.items.index(of: $0) else { return nil }
      return IndexPath(item: idx, section: 1)
    }
    Log.debug("removing items at indices \(removed)")
    self.items ∖= items
    if !removed.isEmpty { collectionView?.deleteItems(at: removed) }
  }

  /// Unregisters for name-change observations from the current document
  private func willChangeDocument(_ notification: Notification) {
    guard let document = DocumentManager.currentDocument else { return }
    receptionist.stopObserving(name: .didRenameDocument, from: document)
  }

  /// Refreshes selection and updates name-change observations
  private func didChangeDocument(_ notification: Notification) {
    refreshSelection()
    guard let document = DocumentManager.currentDocument else { return }
    receptionist.observe(name: .didRenameDocument, from: document,
                         callback: weakMethod(self, DocumentsViewController.documentDidChangeName))
  }

  /// Updates the corresponding cell with the document's new name
  private func documentDidChangeName(_ notification: Notification) {
    Log.debug("userInfo: \(notification.userInfo)")
    guard let newName = notification.newDocumentName else {
      Log.warning("name change notification without new name value in user info")
      return
    }
    Log.debug("current document changed name to '\(newName)'")

    guard let document = notification.object as? Document else {
      fatalError("Expected notification object to be of `Document` type")
    }

    guard let indexPath = indexPathForDocument(document) else {
      fatalError("Unable to resolve indexPath for document: \(document)")
    }

    guard let cell = collectionView?.cellForItem(at: indexPath) as? DocumentCell else {
      fatalError("Unable to retrieve cell for indexPath: \(indexPath)")
    }

    let item = DocumentItem.document(document)
    items[indexPath.item] = item

    cell.item = item
  }

  /// Adds and/or removes items according to the contents of `notification`
  private func didUpdateItems(_ notification: Notification) {
    guard isViewLoaded else { return }

    collectionView?.performBatchUpdates(
      {
        [unowned self] in

        switch (notification.addedItems, notification.removedItems) {

          case let (addedItems?, removedItems?):
            self.addItems(addedItems)
            self.removeItems(removedItems)

          case let (nil, removedItems?):
            self.removeItems(removedItems)

          case let (addedItems?, nil):
            self.addItems(addedItems)

          case (nil, nil):
            break

        }
        
      },
      completion: {
        [unowned self] completed in

        guard completed else { return }
        self.refreshSelection()
      }
    )

  }

  // MARK: UICollectionViewDataSource

  /// Returns two: one for the create item and one for the existing document items
  override func numberOfSections(in collectionView: UICollectionView) -> Int { return 2 }

  /// Returns the number of existing documents when section == 1 and one otherwise
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return section == 1 ? items.count : 1
  }

  /// Returns an instance of `CreateDocumentCell` when section == 0 and an instance of `DocumentCell` otherwise
  override func collectionView(_ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let cell: UICollectionViewCell

    switch (indexPath as NSIndexPath).section {

      case 0:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: CreateDocumentCell.Identifier,
                                                        for: indexPath)
      case 1:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: DocumentCell.Identifier,
                                                        for: indexPath)
        (cell as! DocumentCell).item = items[indexPath.item]

      default:
        fatalError("Invalid section")

    }
    
    return cell
  }

  // MARK: - UICollectionViewDelegate

  /// Returns `true` unless the cell is showing its delete button
  override func collectionView(_ collectionView: UICollectionView,
                               shouldHighlightItemAt indexPath: IndexPath) -> Bool
  {
    guard
      let cell = collectionView.cellForItem(at: indexPath) as? DocumentCell,
      cell.showingDelete
      else
    {
      return true
    }

    cell.hideDelete()
    return false
  }

  /// Creates a new document when section == 0; opens the document otherwise
  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath)
  {
    switch (indexPath as NSIndexPath).section {
      case 0:  DocumentManager.createNewDocument()
      default: DocumentManager.open(item: items[indexPath.row])
    }

    dismiss?()
  }

}
