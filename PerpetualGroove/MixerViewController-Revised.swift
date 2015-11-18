//
//  MixerViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit
import typealias AudioUnit.AudioUnitElement

final class MixerViewController: UICollectionViewController {

  static var currentInstance: MixerViewController? {
    return MIDIPlayerViewController.currentInstance?.mixerViewController
  }

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.SequencerContext
    return receptionist
  }()

  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?

  private weak var sequence: MIDISequence? {
    didSet {
      switch (oldValue, sequence) {
        case let (nil, newValue?):
          observeSequence(newValue)
        case let (oldValue?, nil):
          stopObservingSequence(oldValue)
        case let (oldValue?, newValue?) where oldValue !== newValue:
          stopObservingSequence(oldValue)
          observeSequence(newValue)
        default:
          return
      }
      collectionView?.reloadData()
      if let idx = sequence?.currentTrackIndex { selectTrackAtIndex(idx) }
    }
  }

  /**
  observeSequence:

  - parameter sequence: MIDISequence
  */
  private func observeSequence(sequence: MIDISequence) {
    receptionist.observe(MIDISequence.Notification.DidChangeTrack, from: sequence) {
      [weak self] _ in
        guard let idx = self?.sequence?.currentTrack?.index else { return }
        self?.selectTrackAtIndex(idx)
    }
    receptionist.observe(MIDISequence.Notification.DidAddTrack,
                    from: sequence,
                callback: weakMethod(self, method: MixerViewController.updateTracks))
    receptionist.observe(MIDISequence.Notification.DidRemoveTrack,
                    from: sequence,
                callback: weakMethod(self, method: MixerViewController.updateTracks))
  }

  /**
  stopObservingSequence:

  - parameter sequence: MIDISequence
  */
  private func stopObservingSequence(sequence: MIDISequence) {
    receptionist.stopObserving(MIDISequence.Notification.DidChangeTrack, from: sequence)
    receptionist.stopObserving(MIDISequence.Notification.DidAddTrack,    from: sequence)
    receptionist.stopObserving(MIDISequence.Notification.DidRemoveTrack, from: sequence)
  }

  /** addTrack */
  @IBAction func addTrack() {
    do { try sequence?.addTrackWithInstrument(Sequencer.instrumentWithCurrentSettings()) }
    catch { logError(error, message: "Failed to add new track") }
  }

  /**
  indexPathForSender:

  - parameter sender: UIView

  - returns: NSIndexPath?
  */
  private func indexPathForSender(sender: UIView) -> NSIndexPath? {
    guard let point = collectionView?.convertPoint(sender.center, fromView: sender.superview) else { return nil }
    return collectionView?.indexPathForItemAtPoint(point)
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
    guard section.cellCount > index else { return }
    collectionView?.selectItemAtIndexPath(section[index], animated: animated, scrollPosition: .CenteredHorizontally)
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

      case let (path?, .Right) where section.contains(path) && path.item < section.cellCount - 1:
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
    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument, from: MIDIDocumentManager.self) {
      [weak self] _ in self?.sequence = MIDIDocumentManager.currentDocument?.sequence
    }
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
//  override func viewWillAppear(animated: Bool) {
//    super.viewWillAppear(animated)
//    sequence = MIDIDocumentManager.currentDocument?.sequence
//  }

  /** updateTracks */
  func updateTracks(notification: NSNotification) {
//
//    let section = Section.Instruments
//    switch (notification.addedIndex, notification.removedIndex) {
//      case let (added?, removed?):
//        collectionView?.performBatchUpdates({
//          [weak collectionView = collectionView] in
//            collectionView?.deleteItemsAtIndexPaths([section[removed]])
//            collectionView?.insertItemsAtIndexPaths([section[added]])
//          }, completion: nil)
//      case let (added?, nil):
//        collectionView?.insertItemsAtIndexPaths([section[added]])
//      case let (nil, removed?):
//        collectionView?.deleteItemsAtIndexPaths([section[removed]])
//      case (nil, nil): break
//    }

    let (w, h) = viewSize.unpack
    widthConstraint?.constant = w
    heightConstraint?.constant = h
    collectionView?.contentSize = CGSize(width: w, height: h)

//    collectionViewLayout.invalidateLayout()
    collectionView?.reloadData()
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
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return Section.allCases.count }

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
    let cell = Section.dequeueCellForIndexPath(indexPath)
    switch cell {
      case let cell as MasterCell:
        cell.refresh()
      case let cell as TrackCell:
        cell.track = sequence?.instrumentTracks[indexPath.item]
      default:
        break
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

    var cellCount: Int {
      return MixerViewController.currentInstance?.collectionView?.numberOfItemsInSection(rawValue) ?? 0
    }

    var itemCount: Int {
      switch self {
      case .Master, .Add: return 1
      case .Instruments: return MixerViewController.currentInstance?.sequence?.instrumentTracks.count ?? 0
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

    static func dequeueCellForIndexPath(indexPath: NSIndexPath) -> UICollectionViewCell {
      guard let collectionView = MixerViewController.currentInstance?.collectionView else {
        fatalError("Cannot dequeue a cell without a collection view")
      }
      return collectionView.dequeueReusableCellWithReuseIdentifier(Section(indexPath).identifier, forIndexPath: indexPath)
    }
  }

}