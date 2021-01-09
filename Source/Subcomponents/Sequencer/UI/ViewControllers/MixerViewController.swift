//
//  MixerViewController.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/8/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import typealias AudioToolbox.AudioUnitParameterValue
import typealias AudioUnit.AudioUnitElement
import Combine
import Common
import MoonKit
import UIKit

// MARK: - MixerViewController

/// Controller for displaying the mixer interface.
public final class MixerViewController: UICollectionViewController,
  SecondaryContentProvider
{
  // MARK: Stored Properties

  /// Gesture for enabling track reordering and removal.
  @IBOutlet private var magnifyingGesture: UILongPressGestureRecognizer?

  /// Constrains the width of the collection view.
  private var widthConstraint: NSLayoutConstraint?

  /// Constrains the height of the collection view.
  private var heightConstraint: NSLayoutConstraint?

  /// Subscription for `.sequenceDidChangeTrack` notifications.
  private var trackChangeSubscription: Cancellable?

  /// Subscription for `.sequenceDidAddTrack` notifications.
  private var trackAdditionSubscription: Cancellable?

  /// Subscription for `.sequenceDidRemoveTrack` notifications.
  private var trackRemovalSubscription: Cancellable?

  /// Subscription observing `sequence` value modifications of `controller`.
  private var sequenceSubscription: Cancellable?

  /// The sequence owning the tracks being displayed by the view controller.
  private weak var sequence: Sequencer.Sequence?
  {
    willSet
    {
      // Cancel an existing subscriptions.
      trackChangeSubscription?.cancel()
      trackAdditionSubscription?.cancel()
      trackRemovalSubscription?.cancel()
    }
    didSet
    {
      // Reload data and selection.
      collectionView?.reloadData()
      selectTrack(at: sequence?.currentTrackIndex)

      // Observe the new sequence.
      if let sequence = sequence
      {
        trackChangeSubscription = NotificationCenter.default
          .publisher(for: .sequenceDidChangeTrack, object: sequence)
          .sink(receiveValue: { self.updateTracks($0) })

        trackAdditionSubscription = NotificationCenter.default
          .publisher(for: .sequenceDidAddTrack, object: sequence)
          .sink(receiveValue: { self.updateTracks($0) })

        trackRemovalSubscription = NotificationCenter.default
          .publisher(for: .sequenceDidRemoveTrack, object: sequence)
          .sink(receiveValue: { self.updateTracks($0) })
      }
    }
  }

  /// Holds the expected index for newly inserted tracks.
  private var pendingTrackIndex: Int?

  /// Holds the index of newly inserted tracks.
  private var addedTrackIndex: IndexPath?

  /// Location of the magnified item.
  private var magnifiedCellLocation: CGPoint?

  /// Flag specifying whether `magnifiedItem` is to be deleted. Setting this
  /// property toggles `removalDisplay.isHidden` of a magnified `TrackCell`.
  private var markedForRemoval = false
  {
    didSet
    {
      guard markedForRemoval != oldValue,
            magnifiedItem != nil,
            let cell = collectionView?.cellForItem(at: magnifiedItem!) as? TrackCell
      else
      {
        return
      }

      // Toggle the removal display for the cell
      UIView.animate(withDuration: 0.25)
      {
        cell.removalDisplay.isHidden = !self.markedForRemoval
      }
    }
  }

  /// The track cell whose track's instrument is the target of
  /// sound font/channel changes.
  public weak var soundFontTarget: TrackCell?
  {
    didSet
    {
      switch (oldValue, soundFontTarget)
      {
        case let (oldValue?, newValue?):
          // Deselect the old value and update the instrument controller's
          // instrument with new value. That there is an old value should
          // be enough to ensure there is already an instrument controller.

          oldValue.soundSetImage.isSelected = false

          log.info("Updating instrument of secondary content for new target…")

          (_secondaryContent as? InstrumentViewController)?
            .instrument = newValue.track?.instrument

        case (nil, .some):
          // Present the instrument controller.

          logi("Presenting content for mixer view controller…")

          (parent as? MixerContainer)?
            .presentContent(for: self, completion: { _ in })

        case let (oldValue?, nil):
          // Deselect the old value

          oldValue.soundSetImage.isSelected = false

        case (nil, nil):
          // Nothing to do.

          break
      }
    }
  }

  /// The instrument controller provided to the mixer container for presentation.
  private weak var _secondaryContent: SecondaryContent?
  {
    didSet
    {
      // Update the controller's instrument with that of the sound font target's track.
      instrumentViewController?.instrument = soundFontTarget?.track?.instrument
    }
  }

  // MARK: Computed Properties

  /// `IndexPath` of the cell currently being magnified. This property is a simple
  /// wrapper around `collectionViewLayout.magnifiedItem`.
  @WritablePassThrough(\MixerLayout.magnifiedItem) private var magnifiedItem: IndexPath?

  /// `collectionViewLayout` downcast to its actual type.
  public var mixerLayout: MixerLayout { collectionViewLayout as! MixerLayout }

  /// `_secondaryContent` downcast to its actual type.
  private var instrumentViewController: InstrumentViewController?
  {
    _secondaryContent as? InstrumentViewController
  }

  /// The instrument controller to be given to the mixer container.
  public var secondaryContent: SecondaryContent
  {
    // Check that a controller has not already been created.
    guard _secondaryContent == nil else { return _secondaryContent! }

    // Instantiate and return a controller using the 'Instrument' storyboard.
    guard let viewController = UIStoryboard(name: "Instrument", bundle: nil)
      .instantiateInitialViewController() as? InstrumentViewController
    else
    {
      fatalError("\(#fileID) \(#function) Failed to instantiate view controller.")
    }
    return viewController
  }

  /// Whether an instrument controller is being displayed.
  public var isShowingContent: Bool { _secondaryContent != nil }

  // MARK: Actions

  /// This method uses the current configuration of `controller.auditionInstrument`
  /// to generate a new `InstrumentTrack` for the current sequence.
  @IBAction public func addTrack()
  {
    do
    {
      pendingTrackIndex = Section.tracks.itemCount
      let instrument = try Instrument(preset: controller.auditionInstrument
        .preset)
      try sequence?.insertTrack(instrument: instrument)
    }
    catch
    {
      log.error("Failed to add new track: \(error as NSObject)")
      pendingTrackIndex = nil
    }
  }

  /// Invoked when a `TrackCell` has had its `trackColor` button tapped. This
  /// method updates the track selected as the current track for a sequence.
  @IBAction public func selectItem(_ sender: ImageButtonView)
  {
    guard let location = collectionView?.convert(
      sender.center,
      from: sender.superview
    ),
      let index = collectionView?.indexPathForItem(at: location)?.item
    else
    {
      return
    }
    sequence?.currentTrackIndex = index
  }

  /// Magnifies the pressed cell to indicate additional user interaction in progress.
  @IBAction private func magnifyItem(_ sender: UILongPressGestureRecognizer)
  {
    guard let collectionView = collectionView,
          let sequence = sequence
    else { return }

    switch sender.state
    {
      case .began:
        // Retrieve the index path for the gesture, updating `magnifiedItem`
        // and `magnifiedCellLocation` if the section is `instruments`.

        guard let indexPath = collectionView
          .indexPathForItem(at: sender.location(in: collectionView)),
          Section.tracks.contains(indexPath)
        else
        {
          return
        }
        magnifiedItem = indexPath
        magnifiedCellLocation = sender.location(in: collectionView)

      case .changed:
        // Check the current touch location against the previous touch location
        // to determine the following:
        //   1) Does the `markedForRemoval` flag need to be toggled?
        //   2) Do the track cells need to be reordered?

        guard let previousLocation = magnifiedCellLocation,
              let indexPath = magnifiedItem
        else
        {
          break
        }

        let currentLocation = sender.location(in: collectionView)

        let verticalThreshold = view.bounds.height

        // Check vertical movement.
        switch currentLocation.y
        {
          case verticalThreshold... where !markedForRemoval:
            // Touch has moved below the bottom threshold, set the removal flag.

            markedForRemoval = true
            return

          case ..<verticalThreshold where markedForRemoval:
            // Touch has moved above the bottom threshold, unset the removal flag.

            markedForRemoval = false
            return

          default:
            // Touch has not crossed the removal flag threshold.

            break
        }

        // Only allow reordering when not marked for removal.
        guard !markedForRemoval else { return }

        let horizontalThreshold = (collectionViewLayout as! MixerLayout)
          .itemSize.width * 0.5
        let newPath: IndexPath

        // Check horizontal movement.
        switch currentLocation.x - previousLocation.x
        {
          case horizontalThreshold-->
          where indexPath.item &+ 1 < Section.tracks.itemCount:
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
        sequence.exchangeInstrumentTrack(
          at: indexPath.item,
          with: newPath.item
        )
        magnifiedCellLocation = currentLocation

      case .ended:
        // Handle removal flag if set and nullify `magnifiedItem`.

        defer { magnifiedItem = nil }

        // Check flag and retrieve the marked track's index.
        guard markedForRemoval, magnifiedItem != nil,
              let trackIndex = (collectionView
                .cellForItem(
                  at: magnifiedItem!
                ) as? TrackCell)?
              .track?.index
        else
        {
          return
        }

        if Settings.shared.confirmDeleteTrack
        {
          logw("delete confirmation not yet implemented for tracks")
        }

        // Remove the track from the sequence.
        sequence.removeTrack(at: trackIndex)

      default:
        // Nothing to do.

        break
    }
  }

  /// Selects the `index` item in `Section.tracks` when `index != nil`
  /// and clears selection otherwise.
  ///
  /// - Parameters:
  ///   - index: The index of the track to select.
  ///   - animated: Whether the selection should be animated.
  private func selectTrack(at index: Int?, animated: Bool = false)
  {
    guard let collectionView = collectionView else { return }

    let indexPath = 0 ..< Section.tracks.cellCount(in: collectionView) ~= index
      ? Section.tracks[index!]
      : nil

    collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: [])
  }

  /// Sets `sender` as `soundFontTarget` unless `sender === soundFontTarget`,
  /// in which case `soundFontTarget` is set to `nil`.
  @IBAction private func toggleInstrumentController(for sender: ImageButtonView)
  {
    let trackCell = sender.superview?.superview as? TrackCell
    soundFontTarget = trackCell != nil && soundFontTarget === trackCell!
      ? nil
      : sender.superview?.superview as? TrackCell
  }

  /// Stores a weak reference to `content`.
  public func didShow(content: SecondaryContent) { _secondaryContent = content }

  /// Rolls back the instrument controller's instrument when
  /// `dismissalAction == .cancel`.
  public func didHide(content: SecondaryContent,
                      dismissalAction: SecondaryControllerContainer.DismissalAction)
  {
    guard case .cancel = dismissalAction else { return }
    (content as? InstrumentViewController)?.rollBackInstrument()
  }

  // MARK: Lifecycle

  /// Overridden to create view's mask and constraints.
  override public func viewDidLoad()
  {
    super.viewDidLoad()

    let itemHeight = mixerLayout.itemSize.height

    view.mask = {
      let frame = CGRect(size: CGSize(width: $0, height: $1))
      let view = UIView(frame: frame)
      view.backgroundColor = UIColor.white
      return view
    }(view.bounds.width, itemHeight * 1.1)

    view.constrain(𝗩 ∶| [collectionView!]|, 𝗛 ∶| [collectionView!]|)

    let identifier = Identifier(for: self, tags: "View")
    widthConstraint =
      (view.width == 0 ! 750 --> (identifier + "Width")).activeConstraint
    heightConstraint =
      (view.height == (itemHeight - 20) ! 750 --> (identifier + "Height"))
        .activeConstraint
  }

  /// Overridden to initialize `receptionist` if needed.
  override public func awakeFromNib()
  {
    super.awakeFromNib()
    $magnifiedItem = mixerLayout // Connect property wrapper.
    sequenceSubscription = controller.$sequence.sink { self.sequence = $0 }
  }

  /// Overridden to keep `sequence` current as well as the volume and pan
  /// values for the master cell.
  override public func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)
    sequence = controller.sequence
    (collectionView?.cellForItem(at: Section.master[0]) as? MasterCell)?.refresh()
  }

  // MARK: Updates

  /// Handles track changes specified by `notification`.
  func updateTracks(_ notification: Notification)
  {
    // Make sure there is a collection view to update.
    guard let collectionView = collectionView else { return }

    switch notification.name
    {
      case .sequenceDidAddTrack:
        // Updated `addedTrackIndex` if the track at `added` is pending.
        // Insert a cell for the added track and update the size of the collection.

        guard let added = notification.addedTrackIndex else { break }
        let addedIndexPath = Section.tracks[added]
        if pendingTrackIndex == added { addedTrackIndex = addedIndexPath }
        collectionView.insertItems(at: [addedIndexPath])
        updateSize()

      case .sequenceDidRemoveTrack:
        // Delete the cell for the removed track and update the size of the collection.

        guard let removed = notification.removedTrackIndex else { break }
        collectionView.deleteItems(at: [Section.tracks[removed]])
        updateSize()

      case .sequenceDidChangeTrack:
        // Select the new track.

        selectTrack(at: sequence?.currentTrackIndex, animated: true)

      default:
        fatalError("Unexpected notification received.")
    }
  }

  /// Updates the constants for the width and height constraints as well as the
  /// collection's content size.
  private func updateSize()
  {
    let (itemWidth, itemHeight) = mixerLayout.itemSize.unpack
    let contentWidth = CGFloat(Section.totalItemCount) * itemWidth - 20
    let contentHeight = itemHeight - 20

    widthConstraint?.constant = contentWidth
    heightConstraint?.constant = contentHeight
    collectionView?.contentSize = CGSize(width: contentWidth, height: contentHeight)
  }

  // MARK: Data and Delegation

  /// Returns the number of cases in enumeration `Section`.
  override public func numberOfSections(in collectionView: UICollectionView) -> Int
  {
    Section.sections.count
  }

  /// Returns the `itemCount` for the `Section` case corresponding to `section`.
  override public func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int
  {
    Section(rawValue: section)?.itemCount ?? 0
  }

  /// Returns the cell dequeued by `Section` for the specified index path.
  override public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell
  {
    guard let reuseIdentifier = Section(indexPath)?.reuseIdentifier
    else
    {
      fatalError("Invalid index path: \(indexPath)")
    }

    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: reuseIdentifier,
      for: indexPath
    )

    (cell as? TrackCell)?.track = sequence?.instrumentTracks[indexPath.item]

    return cell
  }

  /// Returns true when `indexPath` specifies an item in section `tracks`.
  override public func collectionView(
    _ collectionView: UICollectionView,
    shouldSelectItemAt indexPath: IndexPath
  ) -> Bool
  {
    Section(indexPath) == .tracks
  }

  /// Updates `currentTrackIndex` of `sequence` with `indexPath.item`.
  override public func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  )
  {
    sequence?.currentTrackIndex = indexPath.item
  }

  /// Selects `cell`, updates `sequence.currentTrackIndex` and displays the
  /// instrument controller when `indexPath == addedTrackIndex`.
  override public func collectionView(_ collectionView: UICollectionView,
                                      willDisplay cell: UICollectionViewCell,
                                      forItemAt indexPath: IndexPath)
  {
    guard addedTrackIndex == indexPath,
          let cell = cell as? TrackCell
    else { return }

    defer
    {
      pendingTrackIndex = nil
      addedTrackIndex = nil
    }

    collectionView.selectItem(
      at: indexPath,
      animated: true,
      scrollPosition: []
    )

    sequence?.currentTrackIndex = indexPath.item

    soundFontTarget = cell
  }
}

// MARK: MixerViewController.Section

private extension MixerViewController
{
  /// Type for specifying a section in the collection.
  enum Section: Int
  {
    /// Single-cell section providing an interface for master volume and pan control.
    case master

    /// Multi-cell section with controls for each track in a sequence.
    case tracks

    /// Single-cell section providing a control for creating a new track in a sequence.
    case add

    /// Initialize with section information in an index path.
    init?(_ indexPath: IndexPath)
    {
      guard let section = Section(rawValue: indexPath.section)
      else
      {
        log.warning("Invalid index path: \(indexPath)")
        return nil
      }
      self = section
    }

    /// Returns an index path for `item` in the section disregarding whether
    /// `item` actually exists.
    subscript(item: Int) -> IndexPath { IndexPath(item: item, section: rawValue) }

    /// Returns whether an item exists in the section as specified by `indexPath`.
    func contains(_ indexPath: IndexPath) -> Bool
    {
      indexPath.section == rawValue && (0 ..< itemCount).contains(indexPath.item)
    }

    /// Returns the number of cells reported by `collectionView` for the section.
    func cellCount(in collectionView: UICollectionView) -> Int
    {
      collectionView.numberOfItems(inSection: rawValue)
    }

    /// Returns the number of items for the section.
    var itemCount: Int
    {
      self == .tracks ? controller.sequence?.instrumentTracks.count ?? 0 : 1
    }

    /// An array of all the index paths that are valid for the section.
    var indexPaths: [IndexPath]
    {
      (0 ..< itemCount).map { IndexPath(item: $0, section: rawValue) }
    }

    /// An array of all possible `Section` values.
    static var sections: [Section] { [.master, .tracks, .add] }

    /// Subscript access for `Section.sections`.
    static subscript(section: Int) -> Section { sections[section] }

    /// Total number of items across all three sections.
    static var totalItemCount: Int { Section.tracks.itemCount &+ 2 }

    /// The cell identifier for cells in the section.
    var reuseIdentifier: String
    {
      switch self
      {
        case .master: return "MasterCell"
        case .add: return "AddTrackCell"
        case .tracks: return "TrackCell"
      }
    }
  }
}

// MARK: - MixerViewController.AddTrackCell

public extension MixerViewController
{
  /// Simple subclass of `UICollectionViewCell` that displays a button over a
  /// background for triggering new track creation.
  final class AddTrackCell: UICollectionViewCell
  {
    /// Button whose action invokes `MixerContainer.ViewController.addTrack`.
    @IBOutlet public var addTrackButton: ImageButtonView!

    /// Overridden to ensure `addTrackButton` state has been reset.
    override public func prepareForReuse()
    {
      super.prepareForReuse()
      addTrackButton.isSelected = false
      addTrackButton.isHighlighted = false
    }
  }
}

// MARK: - MixerViewController.MixerCell

public extension MixerViewController
{
  /// Abstract base for a cell with a label and volume/pan controls.
  class MixerCell: UICollectionViewCell
  {
    /// Controls the volume output for a connection.
    @IBOutlet public var volumeSlider: Slider!

    /// Controls panning for a connection.
    @IBOutlet public var panKnob: Knob!

    /// Accessors for a normalized `volumeSlider.value`.
    public var volume: AudioUnitParameterValue
    {
      get { volumeSlider.value / volumeSlider.maximumValue }
      set { volumeSlider.value = newValue * volumeSlider.maximumValue }
    }

    /// Accessors for `panKnob.value`.
    public var pan: AudioUnitParameterValue
    {
      get { return panKnob.value }
      set { panKnob.value = newValue }
    }
  }
}

// MARK: - MixerContainer.ViewController.MasterCell

public extension MixerViewController
{
  /// `MixerCell` subclass for controlling master volume and pan.
  final class MasterCell: MixerCell
  {
    /// Updates the knob and slider with current values retrieved from `AudioManager`.
    public func refresh()
    {
      volume = audioEngine.mixer.volume
      pan = audioEngine.mixer.pan
    }

    /// Updates `AudioManager.mixer.volume`.
    @IBAction public func volumeDidChange() { audioEngine.mixer.volume = volume }

    /// Updates `AudioManager.mixer.pan`.
    @IBAction public func panDidChange() { audioEngine.mixer.pan = pan }
  }
}

// MARK: - MixerContainer.ViewController.TrackCell

public extension MixerViewController
{
  /// `MixerCell` subclass for controlling property values for an individual track.
  final class TrackCell: MixerCell
  {
    /// Button for toggling track solo status.
    @IBOutlet public var soloButton: LabelButton!

    /// Button for toggling track muting.
    @IBOutlet public var muteButton: LabelButton!

    /// Button for toggling an instrument editor for the track.
    @IBOutlet public var soundSetImage: ImageButtonView!

    /// A text field for displaying/editing the name of the track.
    @IBOutlet public var trackLabel: MarqueeField!

    /// A button for displaying the track's color and setting the current track.
    @IBOutlet public var trackColor: ImageButtonView!

    /// A blurred view that blocks access to track controls and indicates
    /// that the track is slated to be deleted.
    @IBOutlet public var removalDisplay: UIVisualEffectView!

    /// Overridden to keep `trackColor.isSelected` in sync with `isSelected`.
    override public var isSelected: Bool { didSet { trackColor.isSelected = isSelected } }

    /// The action attached to `soloButton`. Toggles `track.solo`.
    @IBAction public func solo() { track?.solo.toggle() }

    /// Flag indicating whether the mute button has been disabled.
    private var muteDisengaged = false
    {
      didSet { muteButton.isEnabled = !muteDisengaged }
    }

    /// Action attached to `muteButton`. Toggles `track.mute`.
    @IBAction public func mute() { track?.mute.toggle() }

    /// Action attached to `volumeSlider`. Updates `track.volume` using `volume`.
    @IBAction public func volumeDidChange() { track?.volume = volume }

    /// Action attached to `panKnob`. Updates `track.pan` using `pan`.
    @IBAction public func panDidChange() { track?.pan = pan }

    /// The track for which the cell provides an interface.
    public weak var track: InstrumentTrack?
    {
      willSet
      {
        muteStatusSubscription?.cancel()
        forceMuteStatusSubscription?.cancel()
        soloStatusSubscription?.cancel()
        nameChangeSubscription?.cancel()
        soundFontChangeSubscription?.cancel()
        programChangeSubscription?.cancel()
      }
      didSet
      {
        guard track != oldValue else { return }
        volume = track?.volume ?? 0
        pan = track?.pan ?? 0
        soundSetImage.image = track?.instrument.soundFont.image
        trackLabel.text = track?.displayName ?? ""
        trackColor.normalTintColor = track?.color.value
        muteButton.isSelected = track?.isMuted ?? false
        soloButton.isSelected = track?.solo ?? false

        if let track = track
        {
          muteStatusSubscription = track.$isMuted.sink { self.muteButton.isSelected = $0 }
          forceMuteStatusSubscription = track.$forceMute.sink
          {
            self.muteDisengaged = $0 || (self.track?.solo == true)
          }
          soloStatusSubscription = track.$solo.sink
          {
            self.soloButton.isSelected = $0
            self.muteDisengaged = $0 || (self.track?.forceMute == true)
          }
          nameChangeSubscription = NotificationCenter.default
            .publisher(for: .trackDidChangeName, object: track)
            .sink { _ in self.trackLabel.text = self.track?.displayName ?? "" }
          soundFontChangeSubscription = NotificationCenter.default
            .publisher(for: .instrumentSoundFontDidChange, object: track.instrument)
            .sink
            {
              _ in guard let track = self.track else { return }
              self.soundSetImage.image = track.instrument.soundFont.image
              self.trackLabel.text = track.displayName
            }
          programChangeSubscription = NotificationCenter.default
            .publisher(for: .instrumentProgramDidChange, object: track.instrument)
            .sink { _ in self.trackLabel.text = self.track?.displayName ?? "" }
        }
      }
    }

    /// Subscription for mute status changes.
    private var muteStatusSubscription: Cancellable?

    /// Subscription for force mute status changes.
    private var forceMuteStatusSubscription: Cancellable?

    /// Subscription for solo status changes.
    private var soloStatusSubscription: Cancellable?

    /// Subscription for name changes.
    private var nameChangeSubscription: Cancellable?

    /// Subscription for sound font changes.
    private var soundFontChangeSubscription: Cancellable?

    /// Subscription for program changes.
    private var programChangeSubscription: Cancellable?
  }
}

// MARK: - MixerViewController.TrackCell + UITextFieldDelegate

extension MixerViewController.TrackCell: UITextFieldDelegate
{
  /// Updates `track.name` when `textField` holds a non-empty string.
  public func textFieldDidEndEditing(_ textField: UITextField)
  {
    if let text = textField.text { track?.name = text }
  }
}

// MARK: - MixerContainer.ViewController.MixerLayout

public extension MixerViewController
{
  /// Custom layout for `MixerContainer.ViewController`.
  final class MixerLayout: UICollectionViewLayout
  {
    public typealias Attributes = UICollectionViewLayoutAttributes

    /// The size of an item in the collection.
    fileprivate let itemSize = CGSize(width: 100, height: 575)

    private let magnifyingTransform = CGAffineTransform(a: 1.1, b: 0, c: 0,
                                                        d: 1.1, tx: 0, ty: 30)

    /// The index path for the cell with a non-identity transform.
    public var magnifiedItem: IndexPath?
    {
      didSet
      {
        guard magnifiedItem != oldValue else { return }

        switch (oldValue, magnifiedItem)
        {
          case (nil, let newIndexPath?):
            attributesCache[newIndexPath]?.transform = magnifyingTransform

          case let (oldIndexPath?, newIndexPath?):
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
    override public func prepare()
    {
      var tuples: [(key: IndexPath, value: Attributes)] = []

      for indexPath in Section.sections.map({ $0.indexPaths }).joined()
      {
        guard let attributes = layoutAttributesForItem(at: indexPath) else { continue }
        tuples.append((key: indexPath, value: attributes))
      }

      attributesCache = OrderedDictionary<IndexPath, Attributes>(tuples)
    }

    /// Returns all cached attributes with frames that intersect `rect`.
    override public func layoutAttributesForElements(in rect: CGRect) -> [Attributes]?
    {
      let result = Array(attributesCache.values.filter { $0.frame.intersects(rect) })
      return result.isEmpty ? nil : result
    }

    /// Returns attributes with an appropriate frame for `indexPath`.
    /// Also sets a non-identity transform when `indexPath == magnifiedItem`.
    override public func layoutAttributesForItem(at indexPath: IndexPath) -> Attributes?
    {
      guard let section = Section(indexPath) else { return nil }

      let attributes = Attributes(forCellWith: indexPath)

      let origin: CGPoint

      switch section
      {
        case .master: origin = .zero
        case .tracks: origin = CGPoint(x: itemSize
            .width * CGFloat(indexPath.item + 1),
            y: 0)
        case .add: origin = CGPoint(
            x: itemSize.width * (CGFloat(Section.tracks.itemCount) + 1),
            y: 0
          )
      }

      attributes.frame = CGRect(origin: origin, size: itemSize)
      attributes.transform = magnifiedItem == indexPath
        ? magnifyingTransform
        : .identity

      return attributes
    }

    /// Overridden to keep track of the magnified cell during track reordering.
    override public func prepare(
      forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]
    )
    {
      defer { super.prepare(forCollectionViewUpdates: updateItems) }

      // Check that the magnified item's location has changed.
      guard let updateItem = updateItems.first,
            let beforePath = updateItem.indexPathBeforeUpdate,
            let afterPath = updateItem.indexPathAfterUpdate,
            magnifiedItem == beforePath, beforePath != afterPath
      else
      {
        return
      }

      magnifiedItem = afterPath
    }

    /// Size derived from the max x and y values from the frame of
    /// the right-most cell attributes.
    override public var collectionViewContentSize: CGSize
    {
      guard let lastItemFrame = attributesCache.last?.value.frame else { return .zero }
      return CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)
    }
  }
}
