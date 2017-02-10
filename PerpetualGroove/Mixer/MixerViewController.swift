//
//  MixerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit
import typealias AudioUnit.AudioUnitElement
import typealias AudioToolbox.AudioUnitParameterValue

/// Controller for displaying the mixer interface.
final class MixerViewController: UICollectionViewController, SecondaryContentProvider {

  /// Gesture for enabling track reordering and removal.
  @IBOutlet private var magnifyingGesture: UILongPressGestureRecognizer!

  /// Monitors `sequence` track changes.
  private let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

  /// Constrains the width of the collection view.
  private var widthConstraint: NSLayoutConstraint?

  /// Constrains the height of the collection view.
  private var heightConstraint: NSLayoutConstraint?

  /// `IndexPath` of the cell currently magnified.
  private var magnifiedItem: IndexPath? {
    get { return (collectionViewLayout as? MixerLayout)?.magnifiedItem }
    set { (collectionViewLayout as? MixerLayout)?.magnifiedItem = newValue }
  }

  /// The source of the track data displayed by the collection.
  fileprivate weak var sequence: Sequence? {
    didSet {
      guard oldValue !== sequence else { return }

      if let oldSequence = oldValue {
        // Stop observing the old sequence.

        receptionist.stopObserving(name: .didChangeTrack, from: oldSequence)
        receptionist.stopObserving(name: .didAddTrack,    from: oldSequence)
        receptionist.stopObserving(name: .didRemoveTrack, from: oldSequence)

      }

      if let sequence = sequence {
        // Observe the new sequence.

        let callback = weakMethod(self, MixerViewController.updateTracks)

        receptionist.observe(name: .didChangeTrack, from: sequence, callback: callback)
        receptionist.observe(name: .didAddTrack,    from: sequence, callback: callback)
        receptionist.observe(name: .didRemoveTrack, from: sequence, callback: callback)

      }

      // Reload data and selection.
      collectionView?.reloadData()
      selectTrack(at: sequence?.currentTrackIndex)

    }

  }

  /// Index expected for the track to be inserted by `sequence`.
  fileprivate var pendingTrackIndex: Int?

  /// Index of the track inserted by `sequence`.
  fileprivate var addedTrackIndex: IndexPath?

  /// Creates a new instrument using the auditioned preset and inserts a track in `sequence` with it.
  @IBAction
  func addTrack() {

    do {

      pendingTrackIndex = Section.tracks.itemCount

      try sequence?.insertTrack(instrument: try Instrument(preset: Sequencer.auditionInstrument.preset))

    } catch {

      Log.error(error, message: "Failed to add new track")

      pendingTrackIndex = nil

    }

  }

  /// Invoked when a `TrackCell` has had its `trackColor` button tapped
  @IBAction
  func selectItem(_ sender: ImageButtonView) {

    guard let collectionView = collectionView else { return }

    let location = collectionView.convert(sender.center, from: sender.superview)

    sequence?.currentTrackIndex = collectionView.indexPathForItem(at: location)?.item

  }

  /// Location of the magnified item.
  private var magnifiedCellLocation: CGPoint?

  /// Flag specifying whether `magnifiedItem` is to be deleted. Setting this property toggles 
  /// `removalDisplay.isHidden` of a magnified `TrackCell`.
  private var markedForRemoval = false {
    didSet {

      guard markedForRemoval != oldValue && magnifiedItem != nil,
            let cell = collectionView?.cellForItem(at: magnifiedItem!) as? TrackCell
        else
      {
        return
      }

      // Toggle the removal display for the cell
      UIView.animate(withDuration: 0.25) {
        [weak cell = cell, marked = markedForRemoval] in cell?.removalDisplay.isHidden = !marked
      }

    }
  }

  /// Magnifies the pressed cell to indicate additional user interaction in progress.
  @IBAction
  private func magnifyItem(_ sender: UILongPressGestureRecognizer) {

    guard let collectionView = collectionView, let sequence = sequence else { return }

    switch sender.state {

      case .began:
        // Retrieve the index path for the gesture, updating `magnifiedItem` and `magnifiedCellLocation` 
        // if the section is `instruments`.

        guard let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)),
              Section.tracks.contains(indexPath)
          else
        {
          return
        }
        magnifiedItem = indexPath
        magnifiedCellLocation = sender.location(in: collectionView)

      case .changed:
        // Check the current touch location against the previous touch location to determine the following:
        // 1) Does the `markedForRemoval` flag need to be toggled?
        // 2) Do the track cells need to be reordered?

        guard let previousLocation = magnifiedCellLocation,
              let indexPath = magnifiedItem
          else
        {
          break
        }

        let currentLocation = sender.location(in: collectionView)

        let verticalThreshold = view.bounds.height

        // Check vertical movement.
        switch currentLocation.y {

          case verticalThreshold--> where !markedForRemoval:
            // Touch has moved below the bottom threshold, set the removal flag.

            markedForRemoval = true
            return

          case <--verticalThreshold where markedForRemoval:
            // Touch has moved above the bottom threshold, unset the removal flag.

            markedForRemoval = false
            return

          default:
            // Touch has not crossed the removal flag threshold.

            break

        }

        // Only allow reordering when not marked for removal.
        guard !markedForRemoval else { return }

        let horizontalThreshold = (collectionViewLayout as! MixerLayout).itemSize.width * 0.5
        let newPath: IndexPath

        // Check horizontal movement.
        switch currentLocation.x - previousLocation.x {

          case horizontalThreshold--> where indexPath.item &+ 1 < Section.tracks.itemCount:
            // Moving right, increment.
            newPath = Section.tracks[indexPath.item + 1]

          case <--horizontalThreshold where indexPath.item &- 1 >= 0:
            // Moving left, decrement.
            newPath = Section.tracks[indexPath.item - 1]

          default:
            // No horizontal movement, return.

            return

        }

        // Move the cell, move the track, and update the cached cell location.
        collectionView.moveItem(at: indexPath, to: newPath)
        sequence.exchangeInstrumentTrack(at: indexPath.item, with: newPath.item)
        magnifiedCellLocation = currentLocation

      case .ended:
        // Handle removal flag if set and nullify `magnifiedItem`.

        defer { magnifiedItem = nil }

        // Check flag and retrieve the marked track's index.
        guard markedForRemoval && magnifiedItem != nil,
          let trackIndex = (collectionView.cellForItem(at: magnifiedItem!) as? TrackCell)?.track?.index
          else
        {
          return
        }

        if Setting.confirmDeleteTrack.value as? Bool == true {
          Log.warning("delete confirmation not yet implemented for tracks")
        }

        // Remove the track from the sequence.
        sequence.removeTrack(at: trackIndex)


      default:
        // Nothing to do.

        break

    }

  }

  /// Selects the `index` item in `Section.tracks` when `index != nil` and clears selection otherwise.
  private func selectTrack(at index: Int?, animated: Bool = false) {

    guard let collectionView = collectionView else { return }

    let indexPath = 0..<Section.tracks.cellCount(in: collectionView) ~= index
                      ? Section.tracks[index!]
                      : nil

    collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])

  }

  /// The track cell whose track's instrument is the target of sound font/channel changes.
  weak var soundFontTarget: TrackCell? {

    didSet {

      switch (oldValue, soundFontTarget) {

        case let (oldValue?, newValue?):
          // Deselect the old value and update the instrument controller's instrument with new value.
          // That there is an old value should be enough to ensure there is already an instrument controller.

          oldValue.soundSetImage.isSelected = false

          Log.debug("Updating instrument of secondary content for new target…")

          (_secondaryContent as? InstrumentViewController)?.instrument = newValue.track?.instrument

        case (nil, .some):
          // Present the instrument controller.

          Log.debug("Presenting content for mixer view controller…")

          (parent as? MixerContainer)?.presentContent(for: self, completion: {_ in})

        case let (oldValue?, nil):
          // Deselect the old value

          oldValue.soundSetImage.isSelected = false

        case (nil, nil):
          // Nothing to do.

          break

      }

    }

  }

  /// Sets `sender` as `soundFontTarget` unless `sender === soundFontTarget`, in which case `soundFontTarget`
  /// is set to `nil`.
  @IBAction
  private func toggleInstrumentController(for sender: ImageButtonView) {
    guard let cell = sender.superview?.superview as? TrackCell else { return }
    soundFontTarget = soundFontTarget === cell ? nil : cell
  }

  /// The instrument controller provided to the mixer container for presentation.
  private weak var _secondaryContent: SecondaryContent? {
    didSet {
      // Update the controller's instrument with that of the sound font target's track.
      (_secondaryContent as? InstrumentViewController)?.instrument = soundFontTarget?.track?.instrument
    }
  }

  /// The instrument controller to be given to the mixer container.
  var secondaryContent: SecondaryContent {

    // Check that a controller has not already been created.
    guard _secondaryContent == nil else { return _secondaryContent! }

    // Instantiate and return a controller using the 'Instrument' storyboard.
    let storyboard = UIStoryboard(name: "Instrument", bundle: nil)
    return storyboard.instantiateInitialViewController() as! InstrumentViewController

  }

  /// Whether an instrument controller is being displayed.
  var isShowingContent: Bool { return _secondaryContent != nil }

  /// Stores a weak reference to `content`.
  func didShow(content: SecondaryContent) { _secondaryContent = content }

  /// Rolls back the instrument controller's instrument when `dismissalAction == .cancel`.
  func didHide(content: SecondaryContent,
               dismissalAction: SecondaryControllerContainer.DismissalAction)
  {
    guard case .cancel = dismissalAction else { return }
    (content as? InstrumentViewController)?.rollBackInstrument()
  }

  /// Flag indicating whether this instance has already initialized it's `receptionist` property.
  private var isReceptionistInitialized = false

  /// Overridden to create view's mask and constraints.
  override func viewDidLoad() {

    super.viewDidLoad()

    let itemHeight = (collectionViewLayout as! MixerLayout).itemSize.height

    view.mask = {
      let frame = CGRect(size: CGSize(width: $0, height: $1))
      let view = UIView(frame: frame)
      view.backgroundColor = UIColor.white
      return view
    }(view.bounds.width, itemHeight * 1.1)

    view.constrain(𝗩∶|[collectionView!]|, 𝗛∶|[collectionView!]|)

    let identifier = Identifier(for: self, tags: "View")
    widthConstraint = (view.width == 0 ! 750 --> (identifier + "Width")).activeConstraint
    heightConstraint = (view.height == (itemHeight - 20) ! 750 --> (identifier + "Height")).activeConstraint

  }

  /// Overridden to initialize `receptionist` if needed.
  override func awakeFromNib() {

    super.awakeFromNib()

    guard !isReceptionistInitialized else { return }

    receptionist.observe(name: .didChangeSequence, from: Sequencer.self) {
      [weak self] _ in self?.sequence = Sequence.current
    }

    isReceptionistInitialized = true

  }

  /// Overridden to keep `sequence` current as well as the volume and pan values for the master cell.
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    sequence = Sequence.current
    (collectionView?.cellForItem(at: Section.master[0]) as? MasterCell)?.refresh()
  }

  /// Handles track changes specified by `notification`.
  func updateTracks(_ notification: Notification) {

    // Make sure there is a collection view to update.
    guard let collectionView = collectionView else { return }

    switch notification.name {

      case Notification.Name(Sequence.NotificationName.didAddTrack.rawValue):
        // Updated `addedTrackIndex` if the track at `added` is pending.
        // Insert a cell for the added track and update the size of the collection.

        guard let added = notification.addedTrackIndex else { break }
        let addedIndexPath = Section.tracks[added]
        if pendingTrackIndex == added { addedTrackIndex = addedIndexPath }
        collectionView.insertItems(at: [addedIndexPath])
        updateSize()

      case Notification.Name(Sequence.NotificationName.didRemoveTrack.rawValue):
        // Delete the cell for the removed track and update the size of the collection.

        guard let removed = notification.removedTrackIndex else { break }
        collectionView.deleteItems(at: [Section.tracks[removed]])
        updateSize()

      case Notification.Name(Sequence.NotificationName.didChangeTrack.rawValue):
        // Select the new track.

        selectTrack(at: sequence?.currentTrackIndex, animated: true)

      default:
        unreachable("Unexpected notification received.")

    }

  }

  /// Updates the constants for the width and height constraints as well as the collection's content size.
  private func updateSize() {

    let (itemWidth, itemHeight) = (collectionViewLayout as! MixerLayout).itemSize.unpack
    let contentWidth = CGFloat(Section.totalItemCount) * itemWidth - 20
    let contentHeight = itemHeight - 20

    widthConstraint?.constant = contentWidth
    heightConstraint?.constant = contentHeight
    collectionView?.contentSize = CGSize(width: contentWidth, height: contentHeight)

  }

  /// Returns the number of cases in enumeration `Section`.
  override func numberOfSections(in collectionView: UICollectionView) -> Int { return Section.sections.count }

  /// Returns the `itemCount` for the `Section` case corresponding to `section`.
  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int
  {
    return Section(rawValue: section)?.itemCount ?? 0
  }

  /// Returns the cell dequeued by `Section` for the specified index path.
  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {

    guard let reuseIdentifier = Section(indexPath)?.reuseIdentifier else {
      fatalError("Invalid index path: \(indexPath)")
    }

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

    (cell as? TrackCell)?.track = sequence?.instrumentTracks[indexPath.item]

    return cell
  }

  /// Returns true when `indexPath` specifies an item in section `tracks`.
  override func  collectionView(_ collectionView: UICollectionView,
                                shouldSelectItemAt indexPath: IndexPath) -> Bool
  {
    return Section(indexPath) == .tracks
  }

  /// Updates `currentTrackIndex` of `sequence` with `indexPath.item`.
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    sequence?.currentTrackIndex = indexPath.item
  }

  /// Selects `cell`, updates `sequence.currentTrackIndex` and displays the instrument controller
  /// when `indexPath == addedTrackIndex`.
  override func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath)
  {

    guard addedTrackIndex == indexPath, let cell = cell as? TrackCell else { return }

    defer {
      pendingTrackIndex = nil
      addedTrackIndex = nil
    }

    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])

    sequence?.currentTrackIndex = indexPath.item

    soundFontTarget = cell

  }

  /// Type for specifying a section in the collection.
  fileprivate enum Section: Int {

    case master  /// Single-cell section providing an interface for master volume and pan control.
    case tracks  /// Multi-cell section with controls for each track in a sequence.
    case add     /// Single-cell section providing a control for creating a new track in a sequence.

    /// Initialize with section information in an index path.
    init?(_ indexPath: IndexPath) {
      guard let section = Section(rawValue: indexPath.section) else {
        Log.warning("Invalid index path: \(indexPath)")
        return nil
      }
      self = section
    }

    /// Returns an index path for `item` in the section disregarding whether `item` actually exists.
    subscript(item: Int) -> IndexPath { return IndexPath(item: item, section: rawValue) }

    /// Returns whether an item exists in the section as specified by `indexPath`.
    func contains(_ indexPath: IndexPath) -> Bool {
      return indexPath.section == rawValue && (0 ..< itemCount).contains(indexPath.item)
    }

    /// Returns the number of cells reported by `collectionView` for the section.
    func cellCount(in collectionView: UICollectionView) -> Int {
      return collectionView.numberOfItems(inSection: rawValue)
    }

    /// Returns the number of items for the section.
    var itemCount: Int { return self == .tracks ? Sequence.current?.instrumentTracks.count ?? 0 : 1 }

    /// An array of all the index paths that are valid for the section.
    var indexPaths: [IndexPath] { return (0..<itemCount).map({IndexPath(item: $0, section: rawValue)}) }

    /// An array of all possible `Section` values.
    static var sections: [Section] { return [.master, .tracks, .add] }

    /// Total number of items across all three sections.
    static var totalItemCount: Int { return Section.tracks.itemCount &+ 2 }

    /// The cell identifier for cells in the section.
    var reuseIdentifier: String {
      switch self {
        case .master: return "MasterCell"
        case .add:    return "AddTrackCell"
        case .tracks: return "TrackCell"
      }
    }

  }

}

/// Simple subclass of `UICollectionViewCell` that displays a button over a background for creating tracks.
final class MixerAddTrackCell: UICollectionViewCell {

  /// Button whose action invokes `MixerViewController.addTrack`.
  @IBOutlet weak var addTrackButton: ImageButtonView!

  /// Overridden to ensure `addTrackButton` state has been reset.
  override func prepareForReuse() {
    super.prepareForReuse()
    addTrackButton.isSelected = false
    addTrackButton.isHighlighted = false
  }

}

/// Abstract base for a cell with a label and volume/pan controls.
class MixerCell: UICollectionViewCell {

  /// Controls the volume output for a connection.
  @IBOutlet weak var volumeSlider: Slider!

  /// Controls panning for a connection.
  @IBOutlet weak var panKnob: Knob!

  /// Accessors for a normalized `volumeSlider.value`.
  var volume: AudioUnitParameterValue {
    get { return volumeSlider.value / volumeSlider.maximumValue }
    set { volumeSlider.value = newValue * volumeSlider.maximumValue }
  }

  /// Accessors for `panKnob.value`.
  var pan: AudioUnitParameterValue {
    get { return panKnob.value }
    set { panKnob.value = newValue }
  }

}

/// `MixerCell` subclass for controlling master volume and pan.
final class MasterCell: MixerCell {

  /// Updates the knob and slider with current values retrieved from `AudioManager`.
  func refresh() {
    volume = AudioManager.mixer.volume
    pan = AudioManager.mixer.pan
  }

  /// Updates `AudioManager.mixer.volume`.
  @IBAction
  func volumeDidChange() { AudioManager.mixer.volume = volume }

  /// Updates `AudioManager.mixer.pan`.
  @IBAction
  func panDidChange() { AudioManager.mixer.pan = pan }

}

/// `MixerCell` subclass for controlling property values for an individual track.
final class TrackCell: MixerCell, UITextFieldDelegate {

  /// Toggle for track soloing.
  @IBOutlet var soloButton: LabelButton!

  /// Toggle for track muting.
  @IBOutlet var muteButton: LabelButton!

  /// Toggle for displaying an instrument editor for the track.
  @IBOutlet var soundSetImage: ImageButtonView!

  /// Control for displaying/editing the name of the track.
  @IBOutlet var trackLabel: MarqueeField!

  /// Button for displaying the track's color and setting the track to be the current track.
  @IBOutlet var trackColor: ImageButtonView!

  /// Blocks access to track controls and indicates that the track is slated to be deleted.
  @IBOutlet var removalDisplay: UIVisualEffectView!

  /// Overridden to keep `trackColor.isSelected` in sync with `isSelected`.
  override var isSelected: Bool {
    get { return super.isSelected }
    set { trackColor.isSelected = newValue; super.isSelected = newValue }
  }

  /// Toggles `track.solo`.
  @IBAction func solo() { track?.solo.toggle() }

  /// Flag indicating whether the mute button has been disabled.
  private var muteDisengaged = false { didSet { muteButton.isEnabled = !muteDisengaged } }

  /// Toggles `track.mute`.
  @IBAction func mute() { track?.mute.toggle() }

  /// Updates `track.volume` using `volume`.
  @IBAction func volumeDidChange() { track?.volume = volume }

  /// Updates `track.pan` using `pan`.
  @IBAction func panDidChange() { track?.pan = pan }

  /// The track for which the cell provides an interface.
  weak var track: InstrumentTrack? {
    didSet {
      guard track != oldValue else { return }
      volume = track?.volume ?? 0
      pan = track?.pan ?? 0
      soundSetImage.image = track?.instrument.soundFont.image
      trackLabel.text = track?.displayName ?? ""
      trackColor.normalTintColor = track?.color.value
      muteButton.isSelected = track?.isMuted ?? false
      soloButton.isSelected = track?.solo ?? false
      receptionist = receptionistForTrack(track)
    }
  }

  /// Listens for any notifications posted by `track`.
  private var receptionist: NotificationReceptionist?

  /// Returns a receptionist registered for monitoring `track` notifications or `nil` if `track == nil`.
  private func receptionistForTrack(_ track: InstrumentTrack?) -> NotificationReceptionist? {

    guard let track = track else { return nil }

    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)

    receptionist.observe(name: .muteStatusDidChange, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.muteButton.isSelected = track.isMuted
    }

    receptionist.observe(name: .forceMuteStatusDidChange, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.muteDisengaged = track.forceMute || track.solo
    }

    receptionist.observe(name: .soloStatusDidChange, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.soloButton.isSelected = track.solo
      self?.muteDisengaged = track.forceMute || track.solo
    }

    receptionist.observe(name: .didChangeName, from: track) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.trackLabel.text = track.displayName
    }

    receptionist.observe(name: .soundFontDidChange, from: track.instrument) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.soundSetImage.image = track.instrument.soundFont.image
      self?.trackLabel.text = track.displayName
    }
    
    receptionist.observe(name: .programDidChange, from: track.instrument) {
      [weak self] _ in
      guard let track = self?.track else { return }
      self?.trackLabel.text = track.displayName
    }
    
    return receptionist
  }

  /// Updates `track.name` when `textField` holds a non-empty string.
  func textFieldDidEndEditing(_ textField: UITextField) {
    if let text = textField.text {
      track?.name = text
    }
  }
  
}

/// Custom layout for `MixerViewController`.
final class MixerLayout: UICollectionViewLayout {

  fileprivate typealias Section = MixerViewController.Section
  typealias Attributes = UICollectionViewLayoutAttributes

  /// The size of an item in the collection.
  fileprivate let itemSize = CGSize(width: 100, height: 575)

  private let magnifyingTransform = CGAffineTransform(a: 1.1, b: 0, c: 0, d: 1.1, tx: 0, ty: 30)

  /// The index path for the cell with a non-identity transform.
  var magnifiedItem: IndexPath? {
    didSet {

      guard magnifiedItem != oldValue else { return }

      switch (oldValue, magnifiedItem) {

      case (nil, let newIndexPath?):
        attributesCache[newIndexPath]?.transform = magnifyingTransform

      case (let oldIndexPath?, let newIndexPath?):
        attributesCache[oldIndexPath]?.transform = .identity
        attributesCache[newIndexPath]?.transform = magnifyingTransform

      case (let oldIndexPath?, nil):
        attributesCache[oldIndexPath]?.transform = .identity

      case (nil, nil):
        break

      }

    }

  }

  /// The cache of cell attributes.
  private var attributesCache = OrderedDictionary<IndexPath, Attributes>()

  /// Overridden to generate attributes for the current set of items.
  override func prepare() {

    var tuples = ContiguousArray<(key: IndexPath, value: Attributes)>(minimumCapacity: Section.totalItemCount)
    for indexPath in Section.sections.map({$0.indexPaths}).joined() {
      guard let attributes = layoutAttributesForItem(at: indexPath) else { continue }
      tuples.append((key: indexPath, value: attributes))
    }

    attributesCache = OrderedDictionary<IndexPath, Attributes>(tuples)

  }

  /// Returns all cached attributes with frames that intersect `rect`.
  override func layoutAttributesForElements(in rect: CGRect) -> [Attributes]? {

    let result = Array(attributesCache.values.filter { $0.frame.intersects(rect) })
    return result.isEmpty ? nil : result

  }

  /// Returns attributes with an appropriate frame for `indexPath`. Also sets a non-identity transform
  /// when `indexPath == magnifiedItem`.
  override func layoutAttributesForItem(at indexPath: IndexPath) -> Attributes? {

    guard let section = Section(indexPath) else { return nil }

    let attributes = Attributes(forCellWith: indexPath)

    let origin: CGPoint

    switch section {
      case .master: origin = .zero
      case .tracks: origin = CGPoint(x: itemSize.width * CGFloat(indexPath.item + 1), y: 0)
      case .add:    origin = CGPoint(x: itemSize.width * (CGFloat(Section.tracks.itemCount) + 1), y: 0)
    }

    attributes.frame = CGRect(origin: origin, size: itemSize)
    attributes.transform = magnifiedItem == indexPath ? magnifyingTransform : .identity

    return attributes
  }

  /// Overridden to keep track of the magnified cell during track reordering.
  override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {

    defer { super.prepare(forCollectionViewUpdates: updateItems) }

    // Check that the magnified item's location has changed.
    guard let updateItem = updateItems.first,
          let beforePath = updateItem.indexPathBeforeUpdate,
          let afterPath = updateItem.indexPathAfterUpdate,
          magnifiedItem == beforePath && beforePath != afterPath
      else
    {
      return
    }

    magnifiedItem = afterPath

  }

  /// Size derived from the max x and y values from the frame of the right-most cell attributes.
  override var collectionViewContentSize: CGSize {
    guard let lastItemFrame = attributesCache.last?.value.frame else { return .zero }
    return CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)
  }

}
