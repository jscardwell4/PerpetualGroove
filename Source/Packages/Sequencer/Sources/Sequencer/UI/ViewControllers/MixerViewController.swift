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
import MoonDev
import UIKit

// MARK: - MixerViewController

/// Controller for displaying the mixer interface.
@available(iOS 14.0, *)
public final class MixerViewController: UICollectionViewController,
                                        SecondaryContentProvider
{

  public typealias Section = MixerLayout.Section

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
  private weak var monitoredSequence: Sequence?
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
      selectTrack(at: monitoredSequence?.currentTrackIndex)

      // Observe the new sequence.
//      if let sequence = monitoredSequence
//      {
//        trackChangeSubscription = NotificationCenter.default
//          .publisher(for: .sequenceDidChangeTrack, object: sequence)
//          .sink(receiveValue: { self.updateTracks($0) })
//
//        trackAdditionSubscription = NotificationCenter.default
//          .publisher(for: .sequenceDidAddTrack, object: sequence)
//          .sink(receiveValue: { self.updateTracks($0) })
//
//        trackRemovalSubscription = NotificationCenter.default
//          .publisher(for: .sequenceDidRemoveTrack, object: sequence)
//          .sink(receiveValue: { self.updateTracks($0) })
//      }
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

          logi("Updating instrument of secondary content for new target…")

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
  @WritablePassthrough(\MixerLayout.magnifiedItem) private var magnifiedItem: IndexPath?

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
      let instrument = try Instrument(preset: auditionInstrument.preset,
                                      audioEngine: audioEngine)
      try monitoredSequence?.insertTrack(instrument: instrument)
    }
    catch
    {
      loge("Failed to add new track: \(error as NSObject)")
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
    monitoredSequence?.currentTrackIndex = index
  }

  /// Magnifies the pressed cell to indicate additional user interaction in progress.
  @IBAction private func magnifyItem(_ sender: UILongPressGestureRecognizer)
  {
    guard let collectionView = collectionView,
          let sequence = monitoredSequence
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
              let track = (collectionView
                            .cellForItem(at: magnifiedItem!) as? TrackCell)?.track,
              let trackIndex = sequence.instrumentTracks.firstIndex(of: track)
        else
        {
          return
        }

        if settings.confirmDeleteTrack
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

    $magnifiedItem = mixerLayout // Connect property wrapper.

    let itemHeight = mixerLayout.itemSize.height

    view.mask = {
      let frame = CGRect(size: CGSize(width: $0, height: $1))
      let view = UIView(frame: frame)
      view.backgroundColor = UIColor.white
      return view
    }(view.bounds.width, itemHeight * 1.1)

    view.constrain(𝗩∶|[collectionView!]|, 𝗛∶|[collectionView!]|)

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
    sequenceSubscription = sequencer.$sequence.sink { self.monitoredSequence = $0 }
  }

  /// Overridden to keep `sequence` current as well as the volume and pan
  /// values for the master cell.
  override public func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)
    monitoredSequence = sequence
    (collectionView?.cellForItem(at: Section.master[0]) as? MasterCell)?.refresh()
  }

  // MARK: Updates

  /// Handles track changes specified by `notification`.
  func updateTracks(_ notification: Notification)
  {
    // Make sure there is a collection view to update.
//    guard let collectionView = collectionView else { return }
//
//    switch notification.name
//    {
//      case .sequenceDidAddTrack:
//        // Updated `addedTrackIndex` if the track at `added` is pending.
//        // Insert a cell for the added track and update the size of the collection.
//
//        guard let added = notification.addedTrackIndex else { break }
//        let addedIndexPath = Section.tracks[added]
//        if pendingTrackIndex == added { addedTrackIndex = addedIndexPath }
//        collectionView.insertItems(at: [addedIndexPath])
//        updateSize()
//
//      case .sequenceDidRemoveTrack:
//        // Delete the cell for the removed track and update the size of the collection.
//
//        guard let removed = notification.removedTrackIndex else { break }
//        collectionView.deleteItems(at: [Section.tracks[removed]])
//        updateSize()
//
//      case .sequenceDidChangeTrack:
//        // Select the new track.
//
//        selectTrack(at: monitoredSequence?.currentTrackIndex, animated: true)
//
//      default:
//        fatalError("Unexpected notification received.")
//    }
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

    (cell as? TrackCell)?.track = monitoredSequence?.instrumentTracks[indexPath.item]

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
    monitoredSequence?.currentTrackIndex = indexPath.item
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

    monitoredSequence?.currentTrackIndex = indexPath.item

    soundFontTarget = cell
  }
}

