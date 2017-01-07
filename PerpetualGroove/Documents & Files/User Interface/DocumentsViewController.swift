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

// FIXME: Deleting the current document halts application. still true???
final class DocumentsViewController: UICollectionViewController {

  // MARK: - Properties

  /// Action invoked when the controller's view is dismissed.
  var dismiss: (() -> Void)?

  /// Removes an item from the collection, deleting the corresponding document.
  @IBAction
  func deleteItem(_ sender: LabelButton) {

    // Get the item from the cell containing `sender`.
    guard let item = (sender.superview?.superview as? DocumentCell)?.item else {
      Log.warning("sender superview is not an item-containing document cell")
      return
    }

    // Ensure the item manager can remove `item`, returning the index from which `item` has been removed.
    guard let index = itemManager.remove(item) else {
      Log.warning("items does not contain item to delete: \(item)")
      return
    }

    let indexPath = IndexPath(item: index, section: 1)

    if Setting.confirmDeleteDocument.value as? Bool == true {
      Log.warning("delete confirmation not yet implemented")
    }

    // Clear selection if this was the selected item.
    if selectedItem == indexPath { selectedItem = nil }

    // Remove the item's cell from the collection view
    collectionView?.deleteItems(at: [indexPath])

    // Delete this item's file on disk.
    DocumentManager.delete(item: item)

  }

  /// Constraint for the collection view's width
  private var widthConstraint: NSLayoutConstraint?

  /// Constraint for the collection view's height
  private var heightConstraint: NSLayoutConstraint?

  /// Overridden to return `true`.
  override var prefersStatusBarHidden: Bool { return true }

  // MARK: - Document items

  /// The object from which the collection's items are retrieved.
  private let itemManager = ItemManager()

  /// The current number of items in the collection.
  fileprivate var itemCount: Int { return itemManager.count }

  /// The currently selected document item; should always represent `DocumentManager.currentDocument`.
  /// When the controller's view is loaded, setting this property causes the collection view to select
  /// the item at this index path or clear the selection if this property is `nil`.
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

  /// Updates the height constraint for the new item count.
  private func itemCountDidChange(from oldCount: Int, to newCount: Int) {
    heightConstraint?.constant = collectionHeight
  }

  /// Updates the width constraint for the new max character count.
  private func characterCountDidChange(from oldCount: Int, to newCount: Int) {
    itemWidth = CGFloat(max(15, newCount)) * UIFont.controlFont.characterWidth
  }

  /// Minimum allowable width for an item's cell.
  fileprivate static let minimumItemWidth: CGFloat = UIFont.controlFont.characterWidth * 15

  /// The current width for an item's cell.
  fileprivate var itemWidth: CGFloat = DocumentsViewController.minimumItemWidth {
    didSet {
      widthConstraint?.constant = itemWidth
    }
  }

  /// The height for an item's cell.
  fileprivate static let itemHeight: CGFloat = UIFont.controlFont.pointSize * 2

  /// The necessary height for displaying all the items in the collection.
  private var collectionHeight: CGFloat {
    return CGFloat(itemManager.count &+ 1) * DocumentsViewController.itemHeight
  }

  /// Uses the value in `DocumentManager.currentDocument` to locate the corresponding element in `items`,
  /// setting `selectedItem` to its equivalent index path. If the collection does not contain such an item,
  /// it is created, a new cell is added to the collection view, and then `selectedItem` updated.
  private func refreshSelection() {

    guard isViewLoaded else { return }

    guard let document = DocumentManager.currentDocument else { selectedItem = nil; return }

    switch itemManager.index(of: DocumentItem.document(document)) {

      case let index?:
        // Select the index path for the current document
        selectedItem = IndexPath(item: index, section: 1)

      default:
        fatalError("Seems like this need revision.")
//        let indexPath = IndexPath(item: itemManager.count, section: 1)
//        itemManager.append(.document(document))
//        collectionView?.performBatchUpdates({ self.collectionView?.insertItems(at: [indexPath]) },
//                                            completion: { completed in
//                                              guard completed else { return }
//                                              self.selectedItem = indexPath })

    }

  }

  // MARK: - View lifecycle

  /// Overridden to set `itemManager.controler` to `self`.
  override func awakeFromNib() {

    super.awakeFromNib()

    itemManager.controller = self

  }

  /// Overridden to add `collectionView` constraints and update `collectionViewLayout.controller`.
  override func viewDidLoad() {

    super.viewDidLoad()

    guard let collectionView = collectionView else {
      fatalError("The view is loaded but `collectionView` is nil.")
    }

    view.constrain(𝗩∶|-[collectionView]-|, 𝗛∶|-[collectionView]-|)

    let id = Identifier(for: self, tags: "Content")
    widthConstraint = (collectionView.width == itemWidth --> (id + "Width")).activeConstraint
    heightConstraint = (collectionView.height == collectionHeight --> (id + "Height")).activeConstraint

    (collectionViewLayout as? DocumentsViewLayout)?.controller = self

  }

  /// Updates the contents of `items` and refreshes the current selection
  override func viewWillAppear(_ animated: Bool) {

    super.viewWillAppear(animated)

    // Make sure we have items to load.
    guard DocumentManager.preferredStorageLocation == .local
       || !DocumentManager.isGatheringMetadataItems
      else
    {
      return
    }

    reloadData()

  }

  // MARK: UICollectionViewDataSource

  /// Returns two: one for the create item and one for the existing document items
  override func numberOfSections(in collectionView: UICollectionView) -> Int { return 2 }

  /// Returns the number of existing documents when section == 1 and one otherwise
  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int
  {
    return section == 1 ? itemManager.count : 1
  }

  /// Returns an instance of `CreateDocumentCell` when section == 0 and an instance of 
  /// `DocumentCell` otherwise.
  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {

    let cell: UICollectionViewCell

    switch indexPath.section {

      case 0:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CreateDocumentCell", for: indexPath)
      case 1:
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCell", for: indexPath)
        (cell as! DocumentCell).item = itemManager[indexPath.item]

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

    guard let cell = collectionView.cellForItem(at: indexPath) as? DocumentCell, cell.isShowingDelete else {
      return true
    }

    cell.hideDelete()

    return false

  }

  /// Creates a new document when section == 0; opens the document otherwise
  override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath)
  {

    switch indexPath.section {
      case 0:  DocumentManager.createNewDocument()
      default: DocumentManager.open(document: Document(fileURL: itemManager[indexPath.row].url))
    }

    dismiss?()

  }

  /// A type for managing the items in the collection.
  private final class ItemManager: Collection {

    // MARK: Presenting a collection interface by wrapping `items`.

    typealias Index = OrderedSet<DocumentItem>.Index
    typealias SubSequence = OrderedSet<DocumentItem>.SubSequence
    typealias Iterator = OrderedSet<DocumentItem>.Iterator
    typealias Indices = OrderedSet<DocumentItem>.Indices

    func makeIterator() -> Iterator { return items.makeIterator() }

    func dropFirst(_ n: Int) -> SubSequence { return items.dropFirst(n) }
    func dropLast(_ n: Int) -> SubSequence { return items.dropLast(n) }
    func prefix(_ maxLength: Int) -> SubSequence { return items.prefix(maxLength) }
    func suffix(_ maxLength: Int) -> SubSequence { return items.suffix(maxLength) }
    func split(maxSplits: Int,
               omittingEmptySubsequences: Bool,
               whereSeparator isSeparator: (DocumentItem) throws -> Bool) rethrows -> [SubSequence]
    {
      return try items.split(maxSplits: maxSplits,
                             omittingEmptySubsequences: omittingEmptySubsequences,
                             whereSeparator: isSeparator)
    }

    var startIndex: Index { return items.startIndex }
    var endIndex: Index { return items.endIndex }
    var count: Int { return items.count }
    var indices: Indices { return items.indices }
    func index(after i: Index) -> Index { return items.index(after: i) }

    subscript(position: Index) -> DocumentItem { return items[position] }
    subscript(bounds: Range<Index>) -> SubSequence { return items[bounds] }

    @discardableResult
    func remove(_ member: DocumentItem) -> Int? {
      guard let index = items.index(of: member) else { return nil }
      items.remove(at: index)
      return index
    }

    @discardableResult
    func remove(at index: Index) -> DocumentItem { return items.remove(at: index) }

    func insert(_ newElement: DocumentItem, at index: Index) {
      items.insert(newElement, at: index)
    }

    func append(_ newElement: DocumentItem) { items.append(newElement) }

    // MARK: Stored properties

    /// The controller for which items are being managed.
    weak var controller: DocumentsViewController?

    /// Receptionist for observing notifications from `DocumentManager`
    private let receptionist: NotificationReceptionist

    /// Set of document items used to populate the collection.
    var items: OrderedSet<DocumentItem> = DocumentManager.items {

      didSet {

        // Update the character count.
        characterCount = items.map({$0.name.characters.count}).max() ?? 0

        let newItemCount = items.count, oldItemCount = oldValue.count


        // Check that the number of items to display has changed.
        guard newItemCount != oldItemCount else { return }

        controller?.itemCountDidChange(from: oldItemCount, to: newItemCount)

      }

    }

    /// Character count for the longest name of an item in `items`.
    var characterCount: Int = 0 {

      didSet {

        // Check that the value has changed.
        guard characterCount != oldValue else { return }

        controller?.characterCountDidChange(from: oldValue, to: characterCount)

      }

    }

    // MARK: Receiving notifications

    /// Default initializer, registers for item-related notifications.
    init() {

      receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

      receptionist.observe(name: .didUpdateItems, from: DocumentManager.self,
                           callback: weakMethod(self, ItemManager.didUpdateItems))

      receptionist.observe(name: .willChangeDocument, from: DocumentManager.self,
                           callback: weakMethod(self, ItemManager.willChangeDocument))

      receptionist.observe(name: .didChangeDocument, from: DocumentManager.self,
                           callback: weakMethod(self, ItemManager.didChangeDocument))

    }

    /// Adds and/or removes items according to the contents of `notification`.
    private func didUpdateItems(_ notification: Notification) {

      let currentItemCount = items.count

      let addedItems = notification.addedItems ?? []
      let removedItems = (notification.removedItems ?? []).filter({items.contains($0)})

      let 𝝙itemCount = addedItems.count &- removedItems.count

      items ∪= addedItems
      items ∖= removedItems

      guard let controller = controller, controller.isViewLoaded else { return }

      let from: Int, to: Int
      let performAction: (UICollectionView) -> ([IndexPath]) -> Void


      switch 𝝙itemCount {

        case 0-->:
          from = currentItemCount
          to = currentItemCount &+ 𝝙itemCount
          performAction = UICollectionView.insertItems

        case <--0:
          from = currentItemCount &+ 𝝙itemCount
          to = currentItemCount
          performAction = UICollectionView.deleteItems

        default:
          return

      }

      let updates = {
        [weak self, bounds = from ..< to] in

        guard let collectionView = self?.controller?.collectionView else { return }

        performAction(collectionView)(bounds.map({IndexPath(item: $0, section: 1)}))

      }

      controller.collectionView?.performBatchUpdates(updates) {
        [weak self] completed in
        
        guard completed else { return }
        
        self?.controller?.refreshSelection()
      }
      
    }

    /// Unregisters for name-change observations from the current document
    private func willChangeDocument(_ notification: Notification) {

      guard let document = DocumentManager.currentDocument else { return }

      receptionist.stopObserving(name: .didRenameDocument, from: document)
      
    }

    /// Updates name-change observations.
    private func didChangeDocument(_ notification: Notification) {

      guard let document = DocumentManager.currentDocument else { return }

      receptionist.observe(name: .didRenameDocument, from: document,
                           callback: weakMethod(self, ItemManager.documentDidChangeName))

      controller?.refreshSelection()

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

      let newItem = DocumentItem.document(document)

      guard let index = items.index(of: newItem) else {
        fatalError("Unable to resolve index in `items` for document: \(document)")
      }

      items[index] = newItem

      assert(items[index].name == newName, "Item was not actually replaced in ordered set.")

      let indexPath = IndexPath(item: index, section: 1)

      guard let cell = controller?.collectionView?.cellForItem(at: indexPath) as? DocumentCell else {
        return
      }

      cell.item = newItem

    }
    
  }

}

/// Custom layout for `DocumentsViewController`.
final class DocumentsViewLayout: UICollectionViewLayout {


  typealias Attributes = UICollectionViewLayoutAttributes

  /// The controller that owns the collection view for this layout.
  fileprivate weak var controller: DocumentsViewController?

  /// The width of each cell in the collection.
  fileprivate var itemWidth: CGFloat = 250

  /// The height of each cell in the collection.
  fileprivate let itemHeight: CGFloat = UIFont.controlFont.pointSize * 2

  /// Cache of attributes calculated for each cell in the collection.
  private var attributesCache: OrderedDictionary<IndexPath, Attributes> = [:]

  /// Overridden to calculate and cache attributes for each cell in the collection.
  override func prepare() {

    let itemCount = (controller?.itemCount ?? 0) &+ 1

    var tuples = ContiguousArray<(key: IndexPath, value: Attributes)>(minimumCapacity: itemCount)

    let indexPaths = [IndexPath(item: 0, section: 0)] + (0..<itemCount).map({IndexPath(item: $0, section: 1)})

    for indexPath in indexPaths {

      guard let attributes = layoutAttributesForItem(at: indexPath) else { continue }

      tuples.append((key: indexPath, value: attributes))

    }

    attributesCache = OrderedDictionary<IndexPath, Attributes>(tuples)

  }

  override var collectionViewContentSize: CGSize {

    guard let lastItemFrame = attributesCache.last?.value.frame else { return .zero }

    return CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)

  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

    let attributes = Array(attributesCache.values.filter({ $0.frame.intersects(rect) }))

    return attributes.isEmpty ? nil : attributes

  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

    let size = CGSize(width: controller?.itemWidth ?? DocumentsViewController.minimumItemWidth,
                      height: DocumentsViewController.itemHeight)

    switch indexPath.section {
      case 0:
        attributes.frame = CGRect(origin: .zero, size: size)
      default:
        attributes.frame = CGRect(origin: CGPoint(x: 0, y: CGFloat(indexPath.item + 1) * size.height),
                                  size: size)
    }

    return attributes
  }

}

/// A cell for displaying the name of an existing document with a control for deleting the document.
final class DocumentCell: UICollectionViewCell {

  @IBOutlet var deleteButton: LabelButton!
  @IBOutlet var label: UILabel!
  @IBOutlet var leadingConstraint: NSLayoutConstraint!

  private(set) var isShowingDelete: Bool = false

  var item: DocumentItem? { didSet { refresh() } }

  func refresh() { label.text = item?.name }

  /// Returns the duration for an animation traveling `distance` or `0.25` when `distance == nil`.
  private func animationDurationForDistance(_ distance: CGFloat?) -> TimeInterval {
    return TimeInterval(CGFloat(0.25) * (distance ?? deleteButton.bounds.width) / deleteButton.bounds.width)
  }

  /// Animates the cell to reveal the cell's delete button. Sets `isShowingDelete` to `true`.
  func revealDelete(_ distance: CGFloat? = nil) {
    UIView.animate(withDuration: animationDurationForDistance(distance),
                    animations: { self.leadingConstraint.constant = -self.deleteButton.bounds.width },
                    completion: {self.isShowingDelete = $0})
  }

  /// Animates the cell to hide the cell's delete button. Sets `isShowingDelete` to `false`.
  func hideDelete(_ distance: CGFloat? = nil) {
    UIView.animate(withDuration: animationDurationForDistance(distance),
                    animations: { self.leadingConstraint.constant = 0 },
                    completion: {self.isShowingDelete = !$0})
  }

  /// Handles the pan gesture attached to the cell for showing and hiding the delete button.
  private func handlePan(_ gesture: BlockActionGesture) {

    guard let pan = gesture as? PanGesture else { return }

    let x = pan.translationInView(self).x

    switch (pan.state, isShowingDelete) {

      case (.began, false) where x < 0,
           (.changed, false) where x < 0:
        leadingConstraint.constant = x

      case (.began, true) where x > 0,
           (.changed, true) where x > 0:
        leadingConstraint.constant = -deleteButton.bounds.width + x

      case (.ended, false) where x <= -deleteButton.bounds.width:
        revealDelete(abs(x))

      case (.ended, _),
           (.cancelled, _),
           (.failed, _):
        hideDelete(abs(x))

      default: break

    }

  }

  /// Creates and attaches the pan gesture for showing and hiding the delete button.
  private func setup() {

    let gesture = PanGesture(handler: unownedMethod(self, DocumentCell.handlePan))
    gesture.confineToView = true
    gesture.delaysTouchesBegan = true
    gesture.axis = .Horizontal

    addGestureRecognizer(gesture)
  }

  /// Overridden to ensure the delete button is not left showing upon reuse.
  override func prepareForReuse() {
    super.prepareForReuse()
    if isShowingDelete { hideDelete() }
  }

  /// Overridden to perform custom setup.
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  /// Overridden to perform custom setup.
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

}

/// A cell for displaying a button for triggering new document creation.
final class CreateDocumentCell: UICollectionViewCell { }
