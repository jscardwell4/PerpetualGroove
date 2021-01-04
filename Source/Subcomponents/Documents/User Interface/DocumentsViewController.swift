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
import Common

/// A view controller for presenting a list of existing documents and a control for creating a new document.
/// Selecting an existing document in the list will load its sequence and update the bookmark data stored
/// in settings.
/// - Bug: Deleting the current document was halting the application, is this still true?
public final class DocumentsViewController: UICollectionViewController {

  /// Action invoked when the controller's view is dismissed.
  public var dismiss: (() -> Void)?

  /// Removes an item from the collection, deleting the corresponding document.
  @IBAction
  public func deleteItem(_ sender: LabelButton) {

    // Get the item from the cell containing `sender`.
    guard let item = (sender.superview?.superview as? DocumentCell)?.item else {
      logw("sender superview is not an item-containing document cell")
      return
    }

    // Ensure the item manager can remove `item`, returning the index from which `item` has been removed.
    guard let index = itemManager.remove(item) else {
      logw("items does not contain item to delete: \(item)")
      return
    }

    let indexPath = IndexPath(item: index, section: 1)

    if SettingsManager.shared.confirmDeleteDocument {
      logw("delete confirmation not yet implemented")
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
  public override var prefersStatusBarHidden: Bool { return true }

  /// The object from which the collection's items are retrieved.
  private let itemManager = ItemManager()

  /// The current number of items in the collection.
  fileprivate var itemCount: Int { return itemManager.count }

  /// The currently selected document item; should always represent `DocumentManager.currentDocument`.
  /// When the controller's view is loaded, setting this property causes the collection view to select
  /// the item at this index path or clear the selection if this property is `nil`.
  private var selectedItem: IndexPath? {

    didSet {

      // Check that the controller's view has loaded.
      guard isViewLoaded else { return }

      logi("\(oldValue?.description ?? "nil") ➞ \(selectedItem?.description ?? "nil")")

      // Make the selection in the collection view, animated and centered vertically.
      collectionView?.selectItem(at: selectedItem, animated: true, scrollPosition: .centeredVertically)

    }

  }

  /// Reloads `collectionView` and refreshes selection
  private func reloadData() {

    // Ensure the reloading occurs on the main thread.
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

    // Check that the controller's view is loaded.
    guard isViewLoaded else { return }

    // Get the current document or clear the selection and return.
    guard let document = DocumentManager.currentDocument else { selectedItem = nil; return }

    // Switch on the item manager's index for `document`.
    switch itemManager.firstIndex(of: DocumentItem.document(document)) {

      case let index?:
        // Update `selectedItem` with an index path consisting of `index` and the document item section.

        selectedItem = IndexPath(item: index, section: 1)

      default:
        // The item manager should have an index for all existing documents.

        fatalError("Seems like this need revision.")

    }

  }

  /// Overridden to set `itemManager.controler` to `self`.
  public override func awakeFromNib() {

    super.awakeFromNib()

    itemManager.controller = self

  }

  /// Overridden to add `collectionView` constraints and update `collectionViewLayout.controller`.
  public override func viewDidLoad() {

    super.viewDidLoad()

    // Get the collection view.
    guard let collectionView = collectionView else {
      fatalError("The view is loaded but `collectionView` is nil.")
    }

    // Register the document cell
    collectionView.register(UINib(nibName: "DocumentCell.xib", bundle: nil),
                            forCellWithReuseIdentifier: "DocumentCellNib")

    // Constrain the collection view to the controller's view.
    view.constrain(𝗩∶|-[collectionView]-|, 𝗛∶|-[collectionView]-|)

    // Create the width and height constaints for the collection view.
    let id = Identifier(for: self, tags: "Content")
    widthConstraint = (collectionView.width == itemWidth --> (id + "Width")).activeConstraint
    heightConstraint = (collectionView.height == collectionHeight --> (id + "Height")).activeConstraint

    // Set the delegate for the collection view's layout.
    (collectionViewLayout as? DocumentsViewLayout)?.controller = self

  }

  /// Overridden to reload the item data when appropriate.
  public override func viewWillAppear(_ animated: Bool) {

    super.viewWillAppear(animated)

    // Make sure we have items to load.
    guard DocumentManager.preferredStorageLocation == .local
       || !DocumentManager.isGatheringMetadataItems
      else
    {
      return
    }

    // Reload the collection.
    reloadData()

  }

  /// Returns two: one for the create item and one for the existing document items
  public override func numberOfSections(in collectionView: UICollectionView) -> Int { return 2 }

  /// Returns the number of existing documents when section == 1 and one otherwise
  public override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int
  {
    return section == 1 ? itemManager.count : 1
  }

  /// Returns an instance of `UICollectionViewCell` when section == 0 and an instance of
  /// `DocumentCell` otherwise.
  public override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {

    let cell: UICollectionViewCell

    // Switch on the section of the index path.
    switch indexPath.section {

      case 0:
        // The index path points to the section containing the document creation control.

        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CreateDocumentCell", for: indexPath)

      case 1:
        // The index path points to the section for document cells.

        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCellNib", for: indexPath)
        (cell as! DocumentCell).item = itemManager[indexPath.item]

      default:
        // The index path points to a non-existent section.

        fatalError("Invalid section")

    }
    
    return cell

  }

  /// A type for managing the items in the collection. `ItemManager` conforms to the `Collection`
  /// protocol via indirection by wrapping calls to its collection of items.
  private final class ItemManager: Collection {

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

    /// The controller for which items are being managed.
    weak var controller: DocumentsViewController?

    /// Receptionist for observing notifications from `DocumentManager`
    private let receptionist: NotificationReceptionist

    /// Set of document items used to populate the collection.
    var items: OrderedSet<DocumentItem> = DocumentManager.items {

      didSet {

        // Update the character count.
        characterCount = items.map({$0.name.count}).max() ?? 0

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

    /// Default initializer, registers for item-related notifications.
    init() {

      receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

      receptionist.observe(name: .didUpdateItems, from: DocumentManager.self,
                           callback: weakCapture(of: self, block:ItemManager.didUpdateItems))

      receptionist.observe(name: .willChangeDocument, from: DocumentManager.self,
                           callback: weakCapture(of: self, block:ItemManager.willChangeDocument))

      receptionist.observe(name: .didChangeDocument, from: DocumentManager.self,
                           callback: weakCapture(of: self, block:ItemManager.didChangeDocument))

    }

    /// Adds and/or removes items according to the contents of `notification`.
    private func didUpdateItems(_ notification: Notification) {

      // Store the current item count.
      let currentItemCount = items.count

      // Retrieve the added and removed items.
      let addedItems = notification.addedItems ?? []
      let removedItems = (notification.removedItems ?? []).filter({items.contains($0)})

      // Calculate the change in the number of items.
      let 𝝙itemCount = addedItems.count &- removedItems.count

      // Update the collection of items.
      items ∪= addedItems
      items ∖= removedItems

      // Check that the controller is non-nil and its view is loaded.
      guard let controller = controller, controller.isViewLoaded else { return }

      // Store the lower and upper bounds for the action to perform.
      let from: Int, to: Int

      // Store the action to perform
      let performAction: (UICollectionView) -> ([IndexPath]) -> Void

      // Handle according to the change in the number of items.
      switch 𝝙itemCount {

        case 0-->:
          // More items have been added than removed. Configure variables for cell insertion.

          from = currentItemCount
          to = currentItemCount &+ 𝝙itemCount
          performAction = UICollectionView.insertItems

        case <--0:
          // More items have been remove than added. Configure variables for cell deletion.

          from = currentItemCount &+ 𝝙itemCount
          to = currentItemCount
          performAction = UICollectionView.deleteItems

        default:
          // The item count has not changed. Nothing to do.

          return

      }

      // Create a closure that updates the collection.
      let updates = {
        [weak self, bounds = from ..< to] in

        // Retrieve the collection view to modify.
        guard let collectionView = self?.controller?.collectionView else { return }

        // Perform the stored action using index paths derived from the stored upper and lower bounds.
        performAction(collectionView)(bounds.map({IndexPath(item: $0, section: 1)}))

      }

      // Perform the batched updates, refreshing the controller's selection upon successful completion.
      controller.collectionView?.performBatchUpdates(updates) {
        [weak self] completed in
        
        guard completed else { return }
        
        self?.controller?.refreshSelection()
      }
      
    }

    /// Unregisters for name-change observations from the outgoing document.
    private func willChangeDocument(_ notification: Notification) {

      // Check that there is a document to stop observing.
      guard let document = DocumentManager.currentDocument else { return }

      // Stop observing the outgoing document.
      receptionist.stopObserving(name: .didRenameDocument, from: document)
      
    }

    /// Registers for name-change observations from the incoming document and refreshes the selection.
    private func didChangeDocument(_ notification: Notification) {

      // Check that there is a document to start observing.
      guard let document = DocumentManager.currentDocument else { return }

      // Start observing the incoming document.
      receptionist.observe(name: .didRenameDocument, from: document,
                           callback: weakCapture(of: self, block:ItemManager.documentDidChangeName))

      // Refresh the controller's selection.
      controller?.refreshSelection()

    }

    /// Updates the corresponding cell with the document's new name
    private func documentDidChangeName(_ notification: Notification) {

      logi("userInfo: \(String(describing: notification.userInfo))")

      // Retrieve the document's new name.
      guard let newName = notification.newDocumentName else {
        logw("name change notification without new name value in user info")
        return
      }

      logi("current document changed name to '\(newName)'")

      // Retrieve the document.
      guard let document = notification.object as? Document else {
        fatalError("Expected notification object to be of `Document` type")
      }

      // Generate a new item for the document.
      let newItem = DocumentItem.document(document)

      // Retrieve the index for the document in the collection of items.
      guard let index = items.index(of: newItem) else {
        fatalError("Unable to resolve index in `items` for document: \(document)")
      }

      // Update the item in the collection of items.
      items[index] = newItem

      assert(items[index].name == newName, "Item was not actually replaced in ordered set.")

      // Create an index path for the document's cell.
      let indexPath = IndexPath(item: index, section: 1)

      // Retrieve the existing cell for the document.
      guard let cell = controller?.collectionView?.cellForItem(at: indexPath) as? DocumentCell else {
        return
      }

      // Update the cell's item to trigger an update to the cell's label text.
      cell.item = newItem

    }
    
  }

  /// Returns `true` unless the cell is showing its delete button
  public override func collectionView(_ collectionView: UICollectionView,
                               shouldHighlightItemAt indexPath: IndexPath) -> Bool
  {

    // Get the cell for `indexPath` and make sure it has revealed its delete control. If the delete
    // control is not showing, return `true` to allow highlighting the cell.
    guard let cell = collectionView.cellForItem(at: indexPath) as? DocumentCell, cell.isShowingDelete else {
      return true
    }

    // Hide the cell's delete control.
    cell.hideDelete()

    // Return `false` to prevent highlighting the cell.
    return false

  }

  /// Creates a new document when section == 0; opens the document otherwise
  public override func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath)
  {

    // Handle according to the item's section.
    switch indexPath.section {

      case 0:
        // The index path points to the document creation section. Create a new document.

        DocumentManager.createNewDocument()

      case 1:
        // The index path points to the document section. Open the document specified by the item.

        DocumentManager.open(document: Document(fileURL: itemManager[indexPath.row].url))

      default:
        // The index path points to a non-existent section.

        fatalError("Invalid section.")

    }

    // Dismiss the controller.
    dismiss?()

  }

}

// MARK: - Layout

/// Custom layout for `DocumentsViewController`.
public final class DocumentsViewLayout: UICollectionViewLayout {


  public typealias Attributes = UICollectionViewLayoutAttributes

  /// The controller that owns the collection view for this layout.
  fileprivate weak var controller: DocumentsViewController?

  /// The width of each cell in the collection.
//  fileprivate var itemWidth: CGFloat = 250

  /// The height of each cell in the collection.
//  fileprivate let itemHeight: CGFloat = UIFont.controlFont.pointSize * 2

  /// Cache of attributes calculated for each cell in the collection.
  private var attributesCache: OrderedDictionary<IndexPath, Attributes> = [:]

  /// Overridden to calculate and cache attributes for each cell in the collection.
  public override func prepare() {

    // Calculate the item count as the number of items specified by the controller plus one for the 
    // document creation cell.
    let itemCount = (controller?.itemCount ?? 0) &+ 1

    // Create a collection to store the tuples that will be used to create `attributesCache`.
    var tuples = ContiguousArray<(key: IndexPath, value: Attributes)>(minimumCapacity: itemCount)

    // Generate an array of all valid index paths for the collection.
    let indexPaths = [IndexPath(item: 0, section: 0)] + (0..<itemCount).map({IndexPath(item: $0, section: 1)})

    // Iterate through the index paths.
    for indexPath in indexPaths {
      // Generate attributes for `indexPath` and append the `(indexPath, attributes)` tuple to `tuples`.

      guard let attributes = layoutAttributesForItem(at: indexPath) else { continue }

      tuples.append((key: indexPath, value: attributes))

    }

    // Assign a new dictionary composed of `tuples` to `attributesCache`.
    attributesCache = OrderedDictionary<IndexPath, Attributes>(tuples)

  }

  /// The max x and y values from the cached attributes of the bottom-most cell.
  public override var collectionViewContentSize: CGSize {

    // Get the frame from the last attributes as it will have the max y value furthest from zero.
    guard let lastItemFrame = attributesCache.last?.value.frame else { return .zero }

    // Return a size derived from the frame's max x and y values.
    return CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)

  }

  /// Returns any cached attributes with frames intersecting `rect`.
  public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

    // Generate an array of cached attributes with frames that intersect `rect`.
    let attributes = Array(attributesCache.values.filter({ $0.frame.intersects(rect) }))

    // Return `nil` if there are no attributes; otherwise, return the attributes.
    return attributes.isEmpty ? nil : attributes

  }

  /// Returns attributes with a frame vertically offset based on `indexPath.item`.
  public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {

    // Create a new attributes instance.
    let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

    // Calculate frame's size.
    let size = CGSize(width: controller?.itemWidth ?? DocumentsViewController.minimumItemWidth,
                      height: DocumentsViewController.itemHeight)

    // Store the origin for the frame
    let origin: CGPoint

    // Handle according to the section of the index path.
    switch indexPath.section {

      case 0:
        // The index path points to the document creation section. This section has one cell that is
        // always located at the collection's origin.

        origin = .zero

      case 1:
        // The index path points to the section of document items. The y offset for the frame is the
        // item specified by the index path multiplied by the cell height plus the height of the 
        // document creation cell.

        origin = CGPoint(x: 0, y: CGFloat(indexPath.item + 1) * size.height)

      default:
        // The index path points to a non-existent section.

        fatalError("Invalid section.")

    }

    // Set the frame using the calculated values.
    attributes.frame = CGRect(origin: origin, size: size)

    return attributes
  }

}


/// A cell for displaying the name of an existing document with a control for deleting the document.
public final class DocumentCell: UICollectionViewCell {

  /// Button for deleting the document represented by the cell.
  @IBOutlet public var deleteButton: LabelButton!

  /// Displays the name of the cell's document.
  @IBOutlet public var label: UILabel!

  /// Used to reveal/hide the delete button.
  @IBOutlet public var leadingConstraint: NSLayoutConstraint!

  /// Whether the cell is currently offset to reveal the delete button.
  public var isShowingDelete: Bool { return leadingConstraint?.constant ?? 0 < 0 }

  /// The item specifying the document to associate with the cell.
  public var item: DocumentItem? { didSet { label.text = item?.name } }

  /// Returns the duration for an animation traveling `distance` or `0.25` when `distance == nil`.
  private func animationDurationForDistance(_ distance: CGFloat?) -> TimeInterval {
    return TimeInterval(CGFloat(0.25) * (distance ?? deleteButton.bounds.width) / deleteButton.bounds.width)
  }

  /// Animates the cell to reveal the cell's delete button. Sets `isShowingDelete` to `true`.
  public func revealDelete(_ distance: CGFloat? = nil) {
    UIView.animate(withDuration: animationDurationForDistance(distance)) {
      self.leadingConstraint.constant = -self.deleteButton.bounds.width
    }
  }

  /// Animates the cell to hide the cell's delete button. Sets `isShowingDelete` to `false`.
  public func hideDelete(_ distance: CGFloat? = nil) {
    UIView.animate(withDuration: animationDurationForDistance(distance)) {
      self.leadingConstraint.constant = 0
    }
  }

  /// Handles the pan gesture attached to the cell for showing and hiding the delete button.
  @IBAction
  private func handlePan(_ gesture: PanGesture) {

    // Get the corresponding x value.
    let x = gesture.translation(in: self).x

    // Handle according to the state of the gesture and the x value.
    switch (gesture.state, x) {

      case (.began, ..<0), (.changed, ..<0):
        // Moving content left. Update the leading constraint using the x value.

        leadingConstraint.constant = x

      case (.began, 0-->), (.changed, 0-->):
        // Moving content right. Update the leading constraint using the x value minus the width of
        // the delete button.

        leadingConstraint.constant = -deleteButton.bounds.width + x

      case (.ended, ...(-deleteButton.bounds.width)):
        // Ended with the delete button showing. Fully reveal the delete button animating with a
        // distance derived from the x value.

        revealDelete(abs(x))

      default:
        // Canceled or ended with delete button hidden. Fully hide the delete button animating with
        // a distance derived from the x value.

        hideDelete(abs(x))

    }

  }

//  /// Creates and attaches the pan gesture for showing and hiding the delete button.
//  private func setup() {
//    //TODO: remove if the nib works
//    let gesture = PanGesture(handler: unownedMethod(self, DocumentCell.handlePan))
//    gesture.confineToView = true
//    gesture.delaysTouchesBegan = true
//    gesture.axis = .horizontal
//
//    addGestureRecognizer(gesture)
//  }

  /// Overridden to ensure the delete button is not left showing upon reuse.
  public override func prepareForReuse() {

    super.prepareForReuse()

    // Reset the leading constraint's constant to its default value for hiding the delete button.
    leadingConstraint?.constant = 0

  }

//  /// Overridden to perform custom setup.
//  override init(frame: CGRect) {
//    super.init(frame: frame)
//    setup()
//  }

//  /// Overridden to perform custom setup.
//  required init?(coder aDecoder: NSCoder) {
//    super.init(coder: aDecoder)
//    setup()
//  }

}
