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
      logDebug("selectedItem: \(selectedItem)")
      guard isViewLoaded() && selectedItem != oldValue else { return }
      collectionView?.selectItemAtIndexPath(selectedItem, animated: true, scrollPosition: .CenteredVertically)
    }
  }

  private var _items: [DocumentItem] = [] {
    didSet {
      print("_items: \(_items)")
      itemNames = _items.map({$0.displayName})
      updateItemSize()
      refreshSelection()
    }
  }
  private var items: [DocumentItem] {
    get {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      return _items
    }
    set {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      _items = newValue
      collectionView?.reloadData()
    }
  }

  private var itemNames: [String] = []


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
    refreshSelection()
  }

  /**
  didCreateDocument:

  - parameter notification: NSNotification
  */
  private func didCreateDocument(notification: NSNotification) {
    logDebug("")
//    refreshSelection()
  }

  /**
  didUpdateItems:

  - parameter notification: NSNotification? = nil
  */
  private func didUpdateItems(notification: NSNotification) {
    guard isViewLoaded() else { return }

    items = MIDIDocumentManager.items
//    func indexPathsForItems(items: [DocumentItem]) -> [NSIndexPath] {
//      return items.flatMap({_items.indexOf($0)}).map({NSIndexPath(forItem: $0, inSection: 1)})
//    }
//
//    switch (notification.addedItems, notification.removedItems) {
//      case let (addedItems?, removedItems?):
//        logDebug("addedItems: \(addedItems)\nremovedItems: \(removedItems)")
//        let indexPathsToRemove = indexPathsForItems(removedItems)
//        _items ∖= removedItems
//        let indexPathsToAdd = (_items.endIndex ..< _items.endIndex + addedItems.count).map({NSIndexPath(forItem: $0, inSection: 1)})
//        _items ∪= addedItems
//        collectionView?.performBatchUpdates({
//          [unowned self] in
//          self.collectionView?.deleteItemsAtIndexPaths(indexPathsToRemove)
//          self.collectionView?.insertItemsAtIndexPaths(indexPathsToAdd)
//          }, completion: nil)
//        break
//
//      case let (nil, removedItems?):
//        logDebug("removedItems: \(removedItems)")
//        let indexPaths = indexPathsForItems(removedItems)
//        _items ∖= removedItems
//        collectionView?.deleteItemsAtIndexPaths(indexPaths)
//        break
//
//      case let (addedItems?, nil):
//        logDebug("addedItems: \(addedItems)")
//        let indexPaths = (_items.endIndex ..< _items.endIndex + (addedItems ∖ _items).count).map({NSIndexPath(forItem: $0, inSection: 1)})
//        guard indexPaths.count > 0 else { break }
//        _items ∪= addedItems
//        collectionView?.insertItemsAtIndexPaths(indexPaths)
//        break
//
//      case (nil, nil):
//        break
//    }
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
        let itemName = itemNames[indexPath.item]
        print("itemName: \(itemName)")
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
