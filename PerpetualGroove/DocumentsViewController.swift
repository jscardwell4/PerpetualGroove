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

  private var selectedItem: NSIndexPath? {
    didSet {
      logDebug("selectedItem: \(selectedItem)")
      guard isViewLoaded() && selectedItem != oldValue else { return }
      collectionView?.selectItemAtIndexPath(selectedItem, animated: true, scrollPosition: .CenteredVertically)
    }
  }

  private var _items: [DocumentItem] = [] {
    didSet {
      logVerbose("_items: \(_items)")
      updateItemSize()
      mainQueue.async { [weak self] in self?.refreshSelection() }
    }
  }
  private var items: [DocumentItem] {
    get { return _items }
    set { _items = newValue; collectionView?.reloadData() }
  }

  /** refreshSelection */
  private func refreshSelection() {
    guard isViewLoaded() else { return }

    guard let currentFileURL = MIDIDocumentManager.currentDocument?.fileURL,
              idx = items.indexOf({$0.URL == currentFileURL})
      else {
        selectedItem = nil
        return
    }
    selectedItem = NSIndexPath(forItem: idx, inSection: 1)
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
    refreshSelection()
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

  private var state: State = []

  /**
  didChangeDocument:

  - parameter notification: NSNotification
  */
  private func didChangeDocument(notification: NSNotification) {
    refreshSelection()
//    if state ∌ .DocumentCreated {  refreshSelection() }
//    else { state ∪= [.DocumentChanged] }
  }

  /**
  didCreateDocument:

  - parameter notification: NSNotification
  */
  private func didCreateDocument(notification: NSNotification) {
//    state ∪= [.DocumentCreated]
  }

  /**
  didUpdateItems:

  - parameter notification: NSNotification? = nil
  */
  private func didUpdateItems(notification: NSNotification) {
    logDebug("")
    guard isViewLoaded() else { return }

    func indexPathsForItems(items: [DocumentItem]) -> [NSIndexPath] {
      return items.flatMap({_items.indexOf($0)}).map({NSIndexPath(forItem: $0, inSection: 1)})
    }

    switch (notification.addedItems, notification.removedItems) {
      case let (addedItems?, removedItems?) where _items !⚭ addedItems && removedItems ⊆ _items:
        logSyncDebug("addedItems: \(addedItems.formattedDescription)\nremovedItems: \(removedItems.formattedDescription)")
        var items = _items
        logSyncDebug("items: \(items.formattedDescription)")
        let indexPathsToRemove = indexPathsForItems(removedItems)
        logSyncDebug("removing items at indices \(indexPathsToRemove.map({$0.item}))")
        items ∖= removedItems
        logSyncDebug("items ∖ removedItems: \(items.formattedDescription)")
        let startIndex = items.endIndex
        let endIndex = startIndex + addedItems.count
        let indexPathsToAdd = (startIndex ..< endIndex).map({NSIndexPath(forItem: $0, inSection: 1)})
        logSyncDebug("inserting items at indices \(indexPathsToAdd.map({$0.item}))")
        items ∪= addedItems
        logSyncDebug("items ∪ addedItems: \(items.formattedDescription)")
        _items = items
        collectionView?.performBatchUpdates({
          [unowned self] in
            self.collectionView?.deleteItemsAtIndexPaths(indexPathsToRemove)
            self.collectionView?.insertItemsAtIndexPaths(indexPathsToAdd)
          }, completion: nil)

      case let (nil, removedItems?) where removedItems ⊆ _items:
        logSyncDebug("removedItems: \(removedItems.formattedDescription)")
        let indexPaths = indexPathsForItems(removedItems)
        logSyncDebug("removing items at indices \(indexPaths.map({$0.item}))")
        _items ∖= removedItems
        collectionView?.deleteItemsAtIndexPaths(indexPaths)

      case let (addedItems?, nil) where _items !⚭ addedItems:
        logSyncDebug("addedItems: \(addedItems.formattedDescription)")
        let indexPaths = (_items.endIndex ..< _items.endIndex + (addedItems ∖ _items).count).map({NSIndexPath(forItem: $0, inSection: 1)})
        guard indexPaths.count > 0 else { break }
        logSyncDebug("inserting items at indices \(indexPaths.map({$0.item}))")
        _items ∪= addedItems
        collectionView?.insertItemsAtIndexPaths(indexPaths)

      default: break
    }
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
        (cell as? DocumentCell)?.item = items[indexPath.item]
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

// MARK: - State
extension DocumentsViewController {

  private struct State: OptionSetType, CustomStringConvertible {
    let rawValue: Int

    static let DocumentCreated = State(rawValue: 0b01)
    static let DocumentChanged = State(rawValue: 0b10)

    var description: String {
      var result = "["
      var flagStrings: [String] = []
      if contains(.DocumentCreated)   { flagStrings.append("DocumentCreated")   }
      if contains(.DocumentChanged) { flagStrings.append("DocumentChanged") }
      result += ", ".join(flagStrings)
      result += " ]"
      return result
    }
  }
  
}
