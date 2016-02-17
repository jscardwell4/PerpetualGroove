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

final class MixerViewController: UICollectionViewController {

  @IBOutlet private var magnifyingGesture: UILongPressGestureRecognizer!

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?

  override var collectionViewLayout: MixerLayout { return super.collectionViewLayout as! MixerLayout }

  private weak var sequence: Sequence? {
    didSet {
      guard oldValue !== sequence else { return }
      if let oldSequence = oldValue { stopObservingSequence(oldSequence) }
      if let sequence = sequence { observeSequence(sequence) }
      collectionView?.reloadData()
      if let idx = sequence?.currentTrackIndex { selectTrackAtIndex(idx) }
    }
  }

  /**
  observeSequence:

  - parameter sequence: Sequence
  */
  private func observeSequence(sequence: Sequence) {
    receptionist.observe(.DidChangeTrack, from: sequence) {
      [weak self] _ in
        guard let idx = self?.sequence?.currentTrack?.index else { return }
        self?.selectTrackAtIndex(idx)
    }
    receptionist.observe(.DidAddTrack,
                    from: sequence,
                callback: weakMethod(self, MixerViewController.updateTracks))
    receptionist.observe(.DidRemoveTrack,
                    from: sequence,
                callback: weakMethod(self, MixerViewController.updateTracks))
  }

  /**
  stopObservingSequence:

  - parameter sequence: Sequence
  */
  private func stopObservingSequence(sequence: Sequence) {
    receptionist.stopObserving(Sequence.Notification.DidChangeTrack, from: sequence)
    receptionist.stopObserving(Sequence.Notification.DidAddTrack,    from: sequence)
    receptionist.stopObserving(Sequence.Notification.DidRemoveTrack, from: sequence)
  }

  private var pendingTrackIndex: Int?
  private var addedTrackIndex: NSIndexPath?

  /** addTrack */
  @IBAction func addTrack() {
    do {
      pendingTrackIndex = Section.Instruments.itemCount
      try sequence?.insertTrackWithInstrument(Sequencer.instrumentWithCurrentSettings())
    } catch {
      logError(error, message: "Failed to add new track")
      pendingTrackIndex = nil
    }
  }

  /**
  indexPathForSender:

  - parameter sender: AnyObject

  - returns: NSIndexPath?
  */
  private func indexPathForSender(sender: AnyObject) -> NSIndexPath? {
    switch sender {
      case let view as UIView:
        return collectionView?.indexPathForItemAtPoint(collectionView!.convertPoint(view.center, fromView: view.superview))
      case let gesture as UILongPressGestureRecognizer:
        return collectionView?.indexPathForItemAtPoint(gesture.locationInView(gesture.view))
      default:
        return nil
    }
  }

  /**
  Invoked when a `TrackCell` has had its `trackColor` button tapped

  - parameter sender: ImageButtonView
  */
  @IBAction func selectItem(sender: ImageButtonView) { 
    sequence?.currentTrackIndex = indexPathForSender(sender)?.item 
  }

  private var magnifiedCellLocation: CGPoint?
  private var markedForRemoval = false {
    didSet {
      guard markedForRemoval != oldValue,
        let item = collectionViewLayout.magnifiedItem,
            cell = collectionView?.cellForItemAtIndexPath(item) as? TrackCell else { return }
      UIView.animateWithDuration(0.25) {
        [weak cell = cell, marked = markedForRemoval] in cell?.removalDisplay.hidden = !marked
      }
    }
  }

  /**
   magnifyItem:

   - parameter sender: UILongPressGestureRecognizer
  */
  @IBAction private func magnifyItem(sender: UILongPressGestureRecognizer) {


    switch sender.state {
      case .Began:
        guard let indexPath = indexPathForSender(sender) where Section.Instruments.contains(indexPath) else { return }
        collectionViewLayout.magnifiedItem = indexPath
        magnifiedCellLocation = sender.locationInView(collectionView)

      case .Changed:
        guard let previousLocation = magnifiedCellLocation, indexPath = collectionViewLayout.magnifiedItem else { break }
        let currentLocation = sender.locationInView(collectionView)

        switch currentLocation.y {
          case let y where y > view.bounds.height && !markedForRemoval: markedForRemoval = true; return
          case let y where y < view.bounds.height && markedForRemoval:  markedForRemoval = false; return
          default:                                                      break
        }

        let threshold = half(MixerLayout.itemSize.width)
        let newPath: NSIndexPath

        switch (currentLocation - previousLocation).unpack {
          case let (x, _) where x > threshold && !markedForRemoval:  newPath = Section.Instruments[indexPath.item + 1]
          case let (x, _) where x < -threshold && !markedForRemoval: newPath = Section.Instruments[indexPath.item - 1]
          default:                                                   return
        }

        guard Section.Instruments.contains(newPath) else { return }
        collectionView?.moveItemAtIndexPath(indexPath, toIndexPath: newPath)
        sequence?.exchangeInstrumentTrackAtIndex(indexPath.item, withTrackAtIndex: newPath.item)
        magnifiedCellLocation = currentLocation

      case .Ended:
        guard let indexPath = collectionViewLayout.magnifiedItem else { return }
        if markedForRemoval, let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? TrackCell {
          deleteTrack(cell.track)
        }
        collectionViewLayout.magnifiedItem = nil

      default: break
    }
  }

  /**
  selectTrackAtIndex:

  - parameter index: Int
  */
  private func selectTrackAtIndex(index: Int, animated: Bool = false) {
    let section = Section.Instruments
    guard section.cellCount(collectionView!) > index else { return }
    collectionView?.selectItemAtIndexPath(section[index], 
                                 animated: animated, 
                           scrollPosition: .None)
  }

  /**
  deleteTrack:

  - parameter track: InstrumentTrack
  */
  func deleteTrack(track: InstrumentTrack?) {
    guard let index = track?.index else { return }
    if SettingsManager.confirmDeleteTrack { logWarning("delete confirmation not yet implemented for tracks") }
    sequence?.removeTrackAtIndex(index)
  }

  weak var soundSetSelectionTargetCell: TrackCell? {
    didSet {
      let instrument: Instrument?
      switch (oldValue, soundSetSelectionTargetCell) {
        case let (oldValue?, newValue?):
          oldValue.soundSetImage.selected = false
          instrument = newValue.track?.instrument
        case let (nil, newValue?):
          instrument = newValue.track?.instrument
        case let (oldValue?, nil):
          oldValue.soundSetImage.selected = false
          instrument = nil
        case (nil, nil):
          instrument = nil
      }
      Sequencer.soundSetSelectionTarget = instrument ?? Sequencer.auditionInstrument
    }
  }

  /**
  registerCellForSoundSetSelection:

  - parameter cell: TrackCell
  */
  func registerCellForSoundSetSelection(cell: TrackCell) {
    guard let collectionView = collectionView where cell.isDescendantOfView(collectionView) else { return }
    if soundSetSelectionTargetCell == cell { soundSetSelectionTargetCell = nil }
    else {
      soundSetSelectionTargetCell = cell
      presentInstrumentController()
    }
  }

  /** presentInstrumentController */
  private func presentInstrumentController(){
    guard let controller = UIStoryboard(name: "Instrument", bundle: nil).instantiateInitialViewController(),
              container = parentViewController as? MixerContainerViewController else { return }
    container.presentSecondaryController(controller)
  }

  private var initialized = false

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    let maskView = UIView(frame: CGRect(size: CGSize(width: view.bounds.width, height: MixerLayout.itemSize.height * 1.1)))
    maskView.backgroundColor = UIColor.whiteColor()
    view.maskView = maskView
  }

  /** awakeFromNib */
  override func awakeFromNib() {
    super.awakeFromNib()
    guard !initialized else { return }
    receptionist.observe(Sequencer.Notification.DidChangeSequence, from: Sequencer.self) {
      [weak self] _ in self?.sequence = Sequencer.sequence
    }
    initialized = true
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    sequence = Sequencer.sequence
  }

  /** updateTracks */
  func updateTracks(notification: NSNotification) {

    guard collectionView != nil else { return }
    guard sequence != nil else { fatalError("internal inconsistency…if sequence is nil what sent this notification?") }

    logDebug("\n".join(
      "total instrument tracks in sequence: \(sequence!.instrumentTracks.count)",
      "total track cells: \(collectionView!.numberOfItemsInSection(Section.Instruments.rawValue))"
      ))

    let section = Section.Instruments

    switch (notification.addedIndex, notification.removedIndex) {

      case let (added?, removed?):
        logDebug("added index: \(added); removed index: \(removed)")
        if pendingTrackIndex == added { addedTrackIndex = section[added] }
        collectionView?.performBatchUpdates({
          [weak collectionView = collectionView] in
            collectionView?.deleteItemsAtIndexPaths([section[removed]])
            collectionView?.insertItemsAtIndexPaths([section[added]])
          }, completion: nil)

      case let (added?, nil):
        if pendingTrackIndex == added { addedTrackIndex = section[added] }
        logDebug("added index: \(added)")
        collectionView?.insertItemsAtIndexPaths([section[added]])

      case let (nil, removed?):
        logDebug("removed index: \(removed)")
        collectionView?.deleteItemsAtIndexPaths([section[removed]])

      case (nil, nil): break
    }

    let (w, h) = viewSize.unpack
    widthConstraint?.constant = w
    heightConstraint?.constant = h
    collectionView?.contentSize = CGSize(width: w, height: h)
  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    let id = Identifier(self, "Internal")

    guard widthConstraint == nil && heightConstraint == nil && view.constraintsWithIdentifier(id).count == 0 else {
      super.updateViewConstraints()
      return
    }

    view.constrain([𝗩|collectionView!|𝗩, 𝗛|collectionView!|𝗛] --> id)

    let (w, h) = viewSize.unpack
    widthConstraint = (view.width => w -!> 750).constraint
    widthConstraint?.identifier = Identifier(self, "View", "Width").string
    widthConstraint?.active = true
    heightConstraint = (view.height => h -!> 750).constraint
    heightConstraint?.identifier = Identifier(self, "View", "Height").string
    heightConstraint?.active = true

    super.updateViewConstraints()
  }

  private var viewSize: CGSize {
    let size = MixerLayout.itemSize
    return CGSize(width: CGFloat(Int(size.width) * (Section.allCases.reduce(0){$0 + $1.itemCount})), height: size.height) - 20
  }

  // MARK: UICollectionViewDataSource

  /**
  numberOfSectionsInCollectionView:

  - parameter collectionView: UICollectionView

  - returns: Int
  */
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return Section.allCases.count
  }

  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return Section(section).itemCount
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
    let cell = Section.dequeueCellForIndexPath(indexPath, collectionView: collectionView)
    switch cell {
      case let cell as MasterCell: cell.refresh()
      case let cell as TrackCell:  cell.track = sequence?.instrumentTracks[indexPath.item]
      default:                     break
    }
    
    return cell
  }

  //// MARK: - UICollectionViewDelegate

  /**
  collectionView:shouldSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: Bool
  */
  override func  collectionView(collectionView: UICollectionView,
    shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
  {
    return Section(indexPath) == .Instruments
  }

  /**
  collectionView:didSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    sequence?.currentTrackIndex = indexPath.item
  }

  /**
   collectionView:willDisplayCell:forItemAtIndexPath:

   - parameter collectionView: UICollectionView
   - parameter cell: UICollectionViewCell
   - parameter indexPath: NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView,
               willDisplayCell cell: UICollectionViewCell,
            forItemAtIndexPath indexPath: NSIndexPath)
  {
    guard addedTrackIndex == indexPath, let cell = cell as? TrackCell else { return }
    defer { pendingTrackIndex = nil; addedTrackIndex = nil }
    collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
    sequence?.currentTrackIndex = indexPath.item
    cell.instrument()
  }
}

extension MixerViewController {

  private enum Section: Int, EnumerableType {
    case Master, Instruments, Add

    /**
     init:

     - parameter value: Int
     */
    init(_ value: Int) {
      guard (0 ... 2) ∋ value else { fatalError("invalid value") }
      self.init(rawValue: value)!
    }

    /**
     init:

     - parameter indexPath: NSIndexPath
     */
    init(_ indexPath: NSIndexPath) { self = Section(rawValue: indexPath.section) ?? .Master }

    /**
     subscript:

     - parameter idx: Int

     - returns: NSIndexPath
     */
    subscript(idx: Int) -> NSIndexPath { return NSIndexPath(forItem: idx, inSection: rawValue) }

    /**
     contains:

     - parameter indexPath: NSIndexPath

     - returns: Bool
     */
    func contains(indexPath: NSIndexPath) -> Bool {
      return indexPath.section == rawValue && (0 ..< itemCount) ∋ indexPath.item
    }

    /**
    cellCount:

    - parameter collectionView: UICollectionView

    - returns: Int
    */
    func cellCount(collectionView: UICollectionView) -> Int {
      return collectionView.numberOfItemsInSection(rawValue)
    }

    var itemCount: Int {
      switch self {
      case .Master, .Add: return 1
      case .Instruments: return Sequencer.sequence?.instrumentTracks.count ?? 0
      }
    }

    static let allCases: [Section] = [.Master, .Instruments, .Add]

    var identifier: String {
      switch self {
      case .Master:      return MasterCell.Identifier
      case .Add:         return AddTrackCell.Identifier
      case .Instruments: return TrackCell.Identifier
      }
    }

    /**
    dequeueCellForIndexPath:collectionView:

    - parameter indexPath: NSIndexPath
    - parameter collectionView: UICollectionView

    - returns: UICollectionViewCell
    */
    static func dequeueCellForIndexPath(indexPath: NSIndexPath,
                         collectionView: UICollectionView) -> UICollectionViewCell
    {
      return collectionView.dequeueReusableCellWithReuseIdentifier(Section(indexPath).identifier,
                                                      forIndexPath: indexPath)
    }
  }
  
}
