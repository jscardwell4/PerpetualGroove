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

  private var notificationReceptionist: NotificationReceptionist!

  @IBOutlet weak var documentsViewLayout: DocumentsViewLayout! { didSet { documentsViewLayout.controller = self } }

  private(set) var itemSize: CGSize = .zero {
    didSet {
      guard itemSize != oldValue else { return }
      guard let layout = collectionView?.collectionViewLayout else { fatalError("wtf") }
      assert(collectionViewLayout == layout)
      collectionView?.collectionViewLayout.invalidateLayout()
      let (w, h) = itemSize.unpack
      let itemCount = CGFloat(items.count + 1)
      collectionViewSize = CGSize(width: w, height: h * itemCount)
    }
  }

  private var collectionViewSize: CGSize = .zero {
    didSet {
      guard collectionViewSize != oldValue else { return }
      let (w, h) = collectionViewSize.unpack
      widthConstraint?.constant = w
      heightConstraint?.constant = h
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
  private func setup() {
    (collectionViewLayout as? DocumentsViewLayout)?.controller = self
    guard case .None = notificationReceptionist else { return }
    let queue = NSOperationQueue.mainQueue()
    notificationReceptionist = NotificationReceptionist(callbacks:
      [
        MIDIDocumentManager.Notification.DidUpdateMetadataItems.rawValue : (MIDIDocumentManager.self, queue, didUpdateItems),
        SettingsManager.Notification.Name.iCloudStorageChanged.rawValue  : (SettingsManager.self, queue, iCloudStorageDidChange)
      ]
    )
  }

  /**
  init:

  - parameter layout: UICollectionViewLayout
  */
  override init(collectionViewLayout layout: UICollectionViewLayout) { super.init(collectionViewLayout: layout); setup() }

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

  // MARK: - Document items

  private var iCloudStorage = SettingsManager.iCloudStorage {
    didSet {
      collectionView?.reloadData()
    }
  }

  private var iCloudItems: [NSMetadataItem] = []
  private var localItems: [LocalDocumentItem] = []

  private var items: [DocumentItemType] { return iCloudStorage ? iCloudItems : localItems }

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
  override func viewWillAppear(animated: Bool) { updateItems() }

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

  private var cellShowingDelete: DocumentCell? {
    return collectionView?.visibleCells().first({($0 as? DocumentCell)?.showingDelete == true}) as? DocumentCell
  }

  // MARK: - Notifications

  /**
  didUpdateFileURLs:

  - parameter notification: NSNotification
  */
  private func didUpdateItems(notification: NSNotification) { updateItems() }

  /**
  iCloudStorageDidChange:

  - parameter notification: NSNotification
  */
  private func iCloudStorageDidChange(notification: NSNotification) {
    guard let value = (notification.userInfo?[SettingsManager.Notification.Key.NewValue.rawValue] as? NSNumber)?.boolValue else {
      return
    }
    iCloudStorage = value
  }

  /** updateItems */
  private func updateItems() {
    iCloudItems = MIDIDocumentManager.metadataItems
    do {
      localItems = try documentsDirectoryContents().filter({
        guard let ext = $0.pathExtension else { return false}
        return ext ~= ~/"^[mM][iI][dD][iI]?$"}
      ).map({LocalDocumentItem($0)})
    } catch {
      logError(error, message: "Failed to obtain local items")
    }
    let font = UIFont.controlFont
    let characterCount = max(CGFloat(items.map({$0.displayName.characters.count ?? 0}).maxElement() ?? 0), 15)
    itemSize = CGSize(width: characterCount * font.characterWidth, height: font.pointSize * 2).integralSize
    collectionView?.reloadData()
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
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(CreateDocumentCell.Identifier, forIndexPath: indexPath)
      default:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(DocumentCell.Identifier, forIndexPath: indexPath)
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
    guard let cell = cellShowingDelete else { return true }
    cell.hideDelete()
    return false
  }

  /**
  collectionView:shouldSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: Bool
  */
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    guard let cell = cellShowingDelete else { return true }
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
      case 0: do { try MIDIDocumentManager.createNewDocument() }
              catch { logError(error, message: "Unable to create new document") }
      default: MIDIDocumentManager.openItem(items[indexPath.row])
    }
    dismiss?()
  }
}
