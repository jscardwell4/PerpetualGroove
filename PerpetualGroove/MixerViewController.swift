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

final class MixerViewController: UICollectionViewController, SecondaryControllerContentDelegate {

  @IBOutlet fileprivate var magnifyingGesture: UILongPressGestureRecognizer!

  fileprivate let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  fileprivate var widthConstraint: NSLayoutConstraint?
  fileprivate var heightConstraint: NSLayoutConstraint?

  override var collectionViewLayout: MixerLayout { return super.collectionViewLayout as! MixerLayout }

  fileprivate weak var sequence: Sequence? {
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
  fileprivate func observeSequence(_ sequence: Sequence) {
    receptionist.observe(name: Sequence.NotificationName.didChangeTrack.rawValue, from: sequence) {
      [weak self] _ in
        guard let idx = self?.sequence?.currentTrack?.index else { return }
        self?.selectTrackAtIndex(idx)
    }
    receptionist.observe(name: Sequence.NotificationName.didAddTrack.rawValue,
                    from: sequence,
                callback: weakMethod(self, MixerViewController.updateTracks))
    receptionist.observe(name: Sequence.NotificationName.didRemoveTrack.rawValue,
                    from: sequence,
                callback: weakMethod(self, MixerViewController.updateTracks))
  }

  /**
  stopObservingSequence:

  - parameter sequence: Sequence
  */
  fileprivate func stopObservingSequence(_ sequence: Sequence) {
    receptionist.stopObserving(name: Sequence.NotificationName.didChangeTrack.rawValue, from: sequence)
    receptionist.stopObserving(name: Sequence.NotificationName.didAddTrack.rawValue,    from: sequence)
    receptionist.stopObserving(name: Sequence.NotificationName.didRemoveTrack.rawValue, from: sequence)
  }

  fileprivate var pendingTrackIndex: Int?
  fileprivate var addedTrackIndex: IndexPath?

  /** addTrack */
  @IBAction func addTrack() {
    do {
      pendingTrackIndex = Section.instruments.itemCount
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
  fileprivate func indexPathForSender(_ sender: AnyObject) -> IndexPath? {
    switch sender {
      case let view as UIView:
        return collectionView?.indexPathForItem(at: collectionView!.convert(view.center, from: view.superview))
      case let gesture as UILongPressGestureRecognizer:
        return collectionView?.indexPathForItem(at: gesture.location(in: gesture.view))
      default:
        return nil
    }
  }

  /**
  Invoked when a `TrackCell` has had its `trackColor` button tapped

  - parameter sender: ImageButtonView
  */
  @IBAction func selectItem(_ sender: ImageButtonView) { 
    sequence?.currentTrackIndex = indexPathForSender(sender)?.item 
  }

  fileprivate var magnifiedCellLocation: CGPoint?
  fileprivate var markedForRemoval = false {
    didSet {
      guard markedForRemoval != oldValue,
        let item = collectionViewLayout.magnifiedItem,
            let cell = collectionView?.cellForItem(at: item as IndexPath) as? TrackCell else { return }
      UIView.animate(withDuration: 0.25, animations: {
        [weak cell = cell, marked = markedForRemoval] in cell?.removalDisplay.isHidden = !marked
      }) 
    }
  }

  /**
   magnifyItem:

   - parameter sender: UILongPressGestureRecognizer
  */
  @IBAction fileprivate func magnifyItem(_ sender: UILongPressGestureRecognizer) {


    switch sender.state {
      case .began:
        guard let indexPath = indexPathForSender(sender) , Section.instruments.contains(indexPath) else { return }
        collectionViewLayout.magnifiedItem = indexPath
        magnifiedCellLocation = sender.location(in: collectionView)

      case .changed:
        guard let previousLocation = magnifiedCellLocation, let indexPath = collectionViewLayout.magnifiedItem else { break }
        let currentLocation = sender.location(in: collectionView)

        switch currentLocation.y {
          case let y where y > view.bounds.height && !markedForRemoval: markedForRemoval = true; return
          case let y where y < view.bounds.height && markedForRemoval:  markedForRemoval = false; return
          default:                                                      break
        }

        let threshold = half(MixerLayout.itemSize.width)
        let newPath: IndexPath

        switch (currentLocation - previousLocation).unpack {
          case let (x, _) where x > threshold && !markedForRemoval:  newPath = Section.instruments[(indexPath as NSIndexPath).item + 1]
          case let (x, _) where x < -threshold && !markedForRemoval: newPath = Section.instruments[(indexPath as NSIndexPath).item - 1]
          default:                                                   return
        }

        guard Section.instruments.contains(newPath) else { return }
        collectionView?.moveItem(at: indexPath as IndexPath, to: newPath)
        sequence?.exchangeInstrumentTrackAtIndex((indexPath as NSIndexPath).item, withTrackAtIndex: (newPath as NSIndexPath).item)
        magnifiedCellLocation = currentLocation

      case .ended:
        guard let indexPath = collectionViewLayout.magnifiedItem else { return }
        if markedForRemoval, let cell = collectionView?.cellForItem(at: indexPath as IndexPath) as? TrackCell {
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
  fileprivate func selectTrackAtIndex(_ index: Int, animated: Bool = false) {
    let section = Section.instruments
    guard section.cellCount(collectionView!) > index else { return }
    collectionView?.selectItem(at: section[index], 
                                 animated: animated, 
                           scrollPosition: UICollectionViewScrollPosition())
  }

  /**
  deleteTrack:

  - parameter track: InstrumentTrack
  */
  func deleteTrack(_ track: InstrumentTrack?) {
    guard let index = track?.index else { return }
    if SettingsManager.confirmDeleteTrack { logWarning("delete confirmation not yet implemented for tracks") }
    sequence?.removeTrackAtIndex(index)
  }

  weak var soundSetSelectionTargetCell: TrackCell? {
    didSet {
      let instrument: Instrument?
      switch (oldValue, soundSetSelectionTargetCell) {
        case let (oldValue?, newValue?):
          oldValue.soundSetImage.isSelected = false
          instrument = newValue.track?.instrument
        case let (nil, newValue?):
          instrument = newValue.track?.instrument
        case let (oldValue?, nil):
          oldValue.soundSetImage.isSelected = false
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
  func registerCellForSoundSetSelection(_ cell: TrackCell) {
    guard let collectionView = collectionView , cell.isDescendant(of: collectionView) else { return }
    if soundSetSelectionTargetCell == cell { soundSetSelectionTargetCell = nil }
    else {
      soundSetSelectionTargetCell = cell
      presentInstrumentController()
    }
  }

  /** presentInstrumentController */
  fileprivate func presentInstrumentController() {
    guard let container = parent as? MixerContainerViewController else { return }
    container.presentContentForDelegate(self)
  }

  fileprivate weak var _secondaryContent: SecondaryControllerContent?
  var secondaryContent: SecondaryControllerContent {
    guard _secondaryContent == nil else { return _secondaryContent! }
    let storyboard = UIStoryboard(name: "Instrument", bundle: nil)
    return storyboard.instantiateInitialViewController() as! InstrumentViewController
  }

  func didShowContent(_ content: SecondaryControllerContent) {
    _secondaryContent = content
  }

  func didHideContent(_ content: SecondaryControllerContent,
                      dismissalAction: SecondaryControllerContainer.DismissalAction)
  {
    guard case .cancel = dismissalAction,
      let instrumentController = content as? InstrumentViewController else { return }
    instrumentController.rollBackInstrument()
  }
  fileprivate var initialized = false

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    let maskHeight = MixerLayout.itemSize.height * 1.1
    let maskView = UIView(frame: CGRect(size: CGSize(width: view.bounds.width, height: maskHeight)))
    maskView.backgroundColor = UIColor.white
    view.mask = maskView
  }

  /** awakeFromNib */
  override func awakeFromNib() {
    super.awakeFromNib()
    guard !initialized else { return }
    receptionist.observe(name: Sequencer.NotificationName.didChangeSequence.rawValue, from: Sequencer.self) {
      [weak self] _ in self?.sequence = Sequencer.sequence
    }
    initialized = true
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    sequence = Sequencer.sequence
  }

  /** updateTracks */
  func updateTracks(_ notification: Notification) {

    guard collectionView != nil else { return }
    guard sequence != nil else {
      fatalError("internal inconsistency…if sequence is nil what sent this notification?")
    }

    logDebug("\n".join(
      "total instrument tracks in sequence: \(sequence!.instrumentTracks.count)",
      "total track cells: \(collectionView!.numberOfItems(inSection: Section.instruments.rawValue))"
      ))

    let section = Section.instruments

    switch (notification.addedIndex, notification.removedIndex) {

      case let (added?, removed?):
        logDebug("added index: \(added); removed index: \(removed)")
        if pendingTrackIndex == added { addedTrackIndex = section[added] }
        collectionView?.performBatchUpdates({
          [weak collectionView = collectionView] in
            collectionView?.deleteItems(at: [section[removed]])
            collectionView?.insertItems(at: [section[added]])
          }, completion: nil)

      case let (added?, nil):
        if pendingTrackIndex == added { addedTrackIndex = section[added] }
        logDebug("added index: \(added)")
        collectionView?.insertItems(at: [section[added]])

      case let (nil, removed?):
        logDebug("removed index: \(removed)")
        collectionView?.deleteItems(at: [section[removed]])

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
    widthConstraint?.isActive = true
    heightConstraint = (view.height => h -!> 750).constraint
    heightConstraint?.identifier = Identifier(self, "View", "Height").string
    heightConstraint?.isActive = true

    super.updateViewConstraints()
  }

  fileprivate var viewSize: CGSize {
    let size = MixerLayout.itemSize
    return CGSize(width: CGFloat(Int(size.width) * (Section.allCases.reduce(0){$0 + $1.itemCount})), height: size.height) - 20
  }

  // MARK: UICollectionViewDataSource

  /**
  numberOfSectionsInCollectionView:

  - parameter collectionView: UICollectionView

  - returns: Int
  */
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return Section.allCases.count
  }

  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return Section(section).itemCount
  }

  /**
  collectionView:cellForItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewCell
  */
  override func collectionView(_ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let cell = Section.dequeueCellForIndexPath(indexPath, collectionView: collectionView)
    switch cell {
      case let cell as MasterCell: cell.refresh()
      case let cell as TrackCell:  cell.track = sequence?.instrumentTracks[(indexPath as NSIndexPath).item]
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
  override func  collectionView(_ collectionView: UICollectionView,
    shouldSelectItemAt indexPath: IndexPath) -> Bool
  {
    return Section(indexPath) == .instruments
  }

  /**
  collectionView:didSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    sequence?.currentTrackIndex = (indexPath as NSIndexPath).item
  }

  /**
   collectionView:willDisplayCell:forItemAtIndexPath:

   - parameter collectionView: UICollectionView
   - parameter cell: UICollectionViewCell
   - parameter indexPath: NSIndexPath
  */
  override func collectionView(_ collectionView: UICollectionView,
               willDisplay cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath)
  {
    guard addedTrackIndex == indexPath, let cell = cell as? TrackCell else { return }
    defer { pendingTrackIndex = nil; addedTrackIndex = nil }
    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
    sequence?.currentTrackIndex = (indexPath as NSIndexPath).item
    cell.instrument()
  }
}

extension MixerViewController {

  fileprivate enum Section: Int, EnumerableType {
    case master, instruments, add

    /**
     init:

     - parameter value: Int
     */
    init(_ value: Int) {
      guard (0 ... 2).contains(value) else { fatalError("invalid value") }
      self.init(rawValue: value)!
    }

    /**
     init:

     - parameter indexPath: NSIndexPath
     */
    init(_ indexPath: IndexPath) { self = Section(rawValue: (indexPath as NSIndexPath).section) ?? .master }

    /**
     subscript:

     - parameter idx: Int

     - returns: NSIndexPath
     */
    subscript(idx: Int) -> IndexPath { return IndexPath(item: idx, section: rawValue) }

    /**
     contains:

     - parameter indexPath: NSIndexPath

     - returns: Bool
     */
    func contains(_ indexPath: IndexPath) -> Bool {
      return indexPath.section == rawValue && (0 ..< itemCount).contains(indexPath.item)
    }

    /**
    cellCount:

    - parameter collectionView: UICollectionView

    - returns: Int
    */
    func cellCount(_ collectionView: UICollectionView) -> Int {
      return collectionView.numberOfItems(inSection: rawValue)
    }

    var itemCount: Int {
      switch self {
      case .master, .add: return 1
      case .instruments: return Sequencer.sequence?.instrumentTracks.count ?? 0
      }
    }

    static let allCases: [Section] = [.master, .instruments, .add]

    var identifier: String {
      switch self {
      case .master:      return MasterCell.Identifier
      case .add:         return AddTrackCell.Identifier
      case .instruments: return TrackCell.Identifier
      }
    }

    /**
    dequeueCellForIndexPath:collectionView:

    - parameter indexPath: NSIndexPath
    - parameter collectionView: UICollectionView

    - returns: UICollectionViewCell
    */
    static func dequeueCellForIndexPath(_ indexPath: IndexPath,
                         collectionView: UICollectionView) -> UICollectionViewCell
    {
      return collectionView.dequeueReusableCell(withReuseIdentifier: Section(indexPath).identifier,
                                                      for: indexPath)
    }
  }
  
}
