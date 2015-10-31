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

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: NSOperationQueue.mainQueue())
    receptionist.logContext = LogManager.SequencerContext
    return receptionist
  }()

  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?

  private weak var sequence: MIDISequence? {
    didSet {
      if let oldSequence = oldValue { stopObservingSequence(oldSequence) }
      if let sequence = sequence { observeSequence(sequence) }
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
    receptionist.observe(MIDISequence.Notification.DidAddTrack,    from: sequence) { [weak self] in self?.updateTracks($0) }
    receptionist.observe(MIDISequence.Notification.DidRemoveTrack, from: sequence) { [weak self] in self?.updateTracks($0) }
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

  private enum Section: Int { case Master, Instruments, Add }

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
    return collectionView?.indexPathForItemAtPoint(collectionView!.convertPoint(sender.center, fromView: sender.superview))
  }

  /**
  Invoked when a `TrackCell` has had its `trackColor` button tapped

  - parameter sender: ImageButtonView
  */
  @IBAction func selectItem(sender: ImageButtonView) { sequence?.currentTrackIndex = indexPathForSender(sender)?.item }

  /**
  selectTrackAtIndex:

  - parameter index: Int
  */
  private func selectTrackAtIndex(index: Int, animated: Bool = false) {
    guard collectionView?.numberOfItemsInSection(1) > index else { return }
    let indexPath = NSIndexPath(forItem: index, inSection: 1)
    collectionView?.selectItemAtIndexPath( indexPath, animated: animated, scrollPosition: .CenteredHorizontally)
  }

  enum ShiftDirection: String { case Left, Right }

  /**
  shiftCell:direction:

  - parameter cell: TrackCell
  - parameter direction: ShiftDirection
  */
  func shiftCell(cell: TrackCell, direction: ShiftDirection) {

    switch (collectionView?.indexPathForCell(cell), direction) {

      case let (indexPath?, .Left) where indexPath.section == 1 && indexPath.item > 0:
        let indexPath2 = NSIndexPath(forItem: indexPath.item - 1, inSection: 1)
        collectionView!.moveItemAtIndexPath(indexPath, toIndexPath: indexPath2)
        sequence?.exchangeInstrumentTrackAtIndex(indexPath.item, withTrackAtIndex: indexPath2.item)

      case let (indexPath?, .Right) where indexPath.section == 1 && indexPath.item < collectionView!.numberOfItemsInSection(1) - 1:
        let indexPath2 = NSIndexPath(forItem: indexPath.item + 1, inSection: 1)
        collectionView!.moveItemAtIndexPath(indexPath, toIndexPath: indexPath2)
        sequence?.exchangeInstrumentTrackAtIndex(indexPath.item, withTrackAtIndex: indexPath2.item)

      default:
        break

    }
  }

  /**
  deleteItem:

  - parameter sender: AnyObject
  */
  @IBAction func deleteItem(sender: UIView) {
    guard let indexPath = indexPathForSender(sender) where indexPath.section == 1 else { return }
    if SettingsManager.confirmDeleteTrack { logWarning("delete confirmation not yet implemented for tracks") }
    sequence?.removeTrackAtIndex(indexPath.item)
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
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    sequence = MIDIDocumentManager.currentDocument?.sequence
  }

  /** updateTracks */
  func updateTracks(notification: NSNotification) {
    guard let cellCount = collectionView?.numberOfItemsInSection(Section.Instruments.rawValue),
              trackCount = sequence?.instrumentTracks.count where cellCount != trackCount else { return }

    let (w, h) = cellSize.unpack
    widthConstraint?.constant = w
    heightConstraint?.constant = h

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

    let (w, h) = cellSize.unpack
    widthConstraint = (view.width => w -!> 750).constraint
    widthConstraint?.identifier = Identifier(self, "View", "Width").string
    widthConstraint?.active = true
    heightConstraint = (view.height => h -!> 750).constraint
    heightConstraint?.identifier = Identifier(self, "View", "Height").string
    heightConstraint?.active = true

    super.updateViewConstraints()
  }

  private var cellSize: CGSize {
    guard let trackCount = sequence?.instrumentTracks.count,
              size = (collectionViewLayout as? MixerLayout)?.itemSize else { return .zero }
    return CGSize(width: CGFloat(Int(size.width) * (trackCount + 2)), height: size.height)
  }

  // MARK: UICollectionViewDataSource

  /**
  numberOfSectionsInCollectionView:

  - parameter collectionView: UICollectionView

  - returns: Int
  */
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 3 }

  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return section == Section.Instruments.rawValue ? sequence?.instrumentTracks.count ?? 0 : 1
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
      case Section.Master.rawValue:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(MasterCell.Identifier, forIndexPath: indexPath)
        (cell as? MasterCell)?.refresh()
      case Section.Add.rawValue:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier("AddTrackCell", forIndexPath: indexPath)
      default:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(TrackCell.Identifier, forIndexPath: indexPath)
        (cell as? TrackCell)?.track = sequence?.instrumentTracks[indexPath.item]
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
  override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return indexPath.section == 1
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
