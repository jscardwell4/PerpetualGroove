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

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?

  override var collectionView: UICollectionView? {
    get { return super.collectionView }
    set { super.collectionView = newValue }
  }

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
    receptionist.observe(Sequence.Notification.DidChangeTrack, from: sequence) {
      [weak self] _ in
        guard let idx = self?.sequence?.currentTrack?.index else { return }
        self?.selectTrackAtIndex(idx)
    }
    receptionist.observe(Sequence.Notification.DidAddTrack,
                    from: sequence,
                callback: weakMethod(self, MixerViewController.updateTracks))
    receptionist.observe(Sequence.Notification.DidRemoveTrack,
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

  /** addTrack */
  @IBAction func addTrack() {
    do { try sequence?.insertTrackWithInstrument(Sequencer.instrumentWithCurrentSettings()) }
    catch { logError(error, message: "Failed to add new track") }
  }

  /**
  indexPathForSender:

  - parameter sender: UIView

  - returns: NSIndexPath?
  */
  private func indexPathForSender(sender: UIView) -> NSIndexPath? {
    return collectionView?.indexPathForItemAtPoint(collectionView!.convertPoint(sender.center, 
                                          fromView: sender.superview))
  }

  /**
  Invoked when a `TrackCell` has had its `trackColor` button tapped

  - parameter sender: ImageButtonView
  */
  @IBAction func selectItem(sender: ImageButtonView) { 
    sequence?.currentTrackIndex = indexPathForSender(sender)?.item 
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
                           scrollPosition: .CenteredHorizontally)
  }

  enum ShiftDirection: String { case Left, Right }

  /**
  shiftCell:direction:

  - parameter cell: TrackCell
  - parameter direction: ShiftDirection
  */
  func shiftCell(cell: TrackCell, direction: ShiftDirection) {
    let section = Section.Instruments
    switch (collectionView?.indexPathForCell(cell), direction) {
      case let (path?, .Left) where section.contains(path) && path.item > 0:
        let path2 = section[path.item - 1]
        collectionView?.moveItemAtIndexPath(path, toIndexPath: path2)
        sequence?.exchangeInstrumentTrackAtIndex(path.item, withTrackAtIndex: path2.item)

      case let (path?, .Right) where section.contains(path) && path.item < section.cellCount(collectionView!) - 1:
        let path2 = section[path.item + 1]
        collectionView?.moveItemAtIndexPath(path, toIndexPath: path2)
        sequence?.exchangeInstrumentTrackAtIndex(path.item, withTrackAtIndex: path2.item)

      default:
        break
    }
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

  private weak var soundSetSelectionTargetCell: TrackCell? {
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
    else { soundSetSelectionTargetCell = cell }
  }

  private var initialized = false

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    collectionView?.translatesAutoresizingMaskIntoConstraints = false
    collectionView?.allowsSelection = true
    collectionView?.clipsToBounds = false
  }

  /** awakeFromNib */
  override func awakeFromNib() {
    super.awakeFromNib()
    guard !initialized else { return }
    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument, from: MIDIDocumentManager.self) {
      [weak self] _ in self?.sequence = MIDIDocumentManager.currentDocument?.sequence
    }
    initialized = true
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    sequence = MIDIDocumentManager.currentDocument?.sequence
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
        collectionView?.performBatchUpdates({
          [weak collectionView = collectionView] in
            collectionView?.deleteItemsAtIndexPaths([section[removed]])
            collectionView?.insertItemsAtIndexPaths([section[added]])
          }, completion: nil)

      case let (added?, nil):
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
    guard let size = (collectionViewLayout as? MixerLayout)?.itemSize else { return .zero }
    return CGSize(width: CGFloat(Int(size.width) * (Section.allCases.reduce(0){$0 + $1.itemCount})), height: size.height)
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
    shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
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
    func contains(indexPath: NSIndexPath) -> Bool { return indexPath.section == rawValue }

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
      case .Instruments: return MIDIDocumentManager.currentDocument?.sequence?.instrumentTracks.count ?? 0
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
    static func dequeueCellForIndexPath(indexPath: NSIndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
      return collectionView.dequeueReusableCellWithReuseIdentifier(Section(indexPath).identifier, forIndexPath: indexPath)
    }
  }
  
}
