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

  private var receptionist: NotificationReceptionist?

  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?

  private enum Section: Int { case Master, Instruments, Add }

  /** addTrack */
  @IBAction func addTrack() {
    guard let sequence = Sequencer.sequence else { logWarning("Cannot add a track without a sequence"); return }
    let instrument = Sequencer.instrumentWithCurrentSettings()
    do { try sequence.newTrackWithInstrument(instrument) }
    catch { logError(error, message: "Failed to add new track") }
  }

  /**
  indexPathForSender:

  - parameter sender: UIView

  - returns: NSIndexPath?
  */
  private func indexPathForSender(sender: UIView) -> NSIndexPath? {
    guard let collectionView = collectionView else { return nil }
    return collectionView.indexPathForItemAtPoint(collectionView.convertPoint(sender.center, fromView: sender.superview))
  }

  /**
  Invoked when a `TrackCell` has had its `trackColor` button tapped

  - parameter sender: ImageButtonView
  */
  @IBAction func selectItem(sender: ImageButtonView) {
    guard let indexPath = indexPathForSender(sender) where indexPath.section == 1 else { return }
    Sequencer.sequence?.currentTrack = Sequencer.sequence?.instrumentTracks[indexPath.item]
  }

  enum ShiftDirection: String { case Left, Right }

  /**
  shiftCell:direction:

  - parameter cell: TrackCell
  - parameter direction: ShiftDirection
  */
  func shiftCell(cell: TrackCell, direction: ShiftDirection) {
    guard let collectionView = collectionView else { return }

    switch (collectionView.indexPathForCell(cell), direction) {

      case let (indexPath?, .Left) where indexPath.section == 1 && indexPath.item > 0:
        let indexPath2 = NSIndexPath(forItem: indexPath.item - 1, inSection: 1)
        collectionView.moveItemAtIndexPath(indexPath, toIndexPath: indexPath2)
        Sequencer.sequence?.exchangeInstrumentTrackAtIndex(indexPath.item, withTrackAtIndex: indexPath2.item)

      case let (indexPath?, .Right) where indexPath.section == 1 && indexPath.item < collectionView.numberOfItemsInSection(1) - 1:
        let indexPath2 = NSIndexPath(forItem: indexPath.item + 1, inSection: 1)
        collectionView.moveItemAtIndexPath(indexPath, toIndexPath: indexPath2)
        Sequencer.sequence?.exchangeInstrumentTrackAtIndex(indexPath.item, withTrackAtIndex: indexPath2.item)

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
    Sequencer.sequence?.removeTrack(Sequencer.sequence!.instrumentTracks[indexPath.item])
  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    collectionView?.translatesAutoresizingMaskIntoConstraints = false
    collectionView?.allowsSelection = true
    collectionView?.clipsToBounds = false

    guard receptionist == nil else { return }
    receptionist = generateNotificationReceptionist()
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    if let idx = Sequencer.sequence?.currentTrackIndex {
      collectionView?.selectItemAtIndexPath(NSIndexPath(forItem: idx, inSection: 1),
                                   animated: false,
                             scrollPosition: .CenteredHorizontally)
    }
  }

  /**
  generateNotificationReceptionist

  - returns: NotificationReceptionist
  */
  private func generateNotificationReceptionist() -> NotificationReceptionist {
    let receptionist = NotificationReceptionist()
    receptionist.logContext = LogManager.SequencerContext

    let queue = NSOperationQueue.mainQueue()

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument, from: MIDIDocumentManager.self, queue: queue) {
      [weak self] in self?.documentChanged($0)
    }

    guard let sequence = Sequencer.sequence else { return receptionist }

    receptionist.observe(MIDISequence.Notification.DidChangeTrack, from: sequence, queue: queue) { 
      [weak self] in self?.trackChanged($0) 
    }
    receptionist.observe(MIDISequence.Notification.DidAddTrack,    from: sequence, queue: queue) { 
      [weak self] in self?.updateTracks($0) 
    }
    receptionist.observe(MIDISequence.Notification.DidRemoveTrack, from: sequence, queue: queue) { 
      [weak self] in self?.updateTracks($0) 
    }

    return receptionist
  }

  /**
  currentDocumentDidChange:

  - parameter notification: NSNotification
  */
  private func documentChanged(notification: NSNotification) {
    receptionist = generateNotificationReceptionist()
    collectionView?.reloadData()
    if let currentTrackIndex = Sequencer.sequence?.currentTrack?.index {
      collectionView?.selectItemAtIndexPath(NSIndexPath(forItem: currentTrackIndex, inSection: 1),
                                   animated: true,
                             scrollPosition: .CenteredHorizontally)
    }
  }

  /**
  trackChanged:

  - parameter notification: NSNotification
  */
  private func trackChanged(notification: NSNotification) {

    if let newTrack = notification.userInfo?[MIDISequence.Notification.Key.Track.rawValue] as? InstrumentTrack,
      idx = Sequencer.sequence?.instrumentTracks.indexOf(newTrack)
    {
      collectionView?.selectItemAtIndexPath(NSIndexPath(forItem: idx, inSection: 1),
                                   animated: true,
                             scrollPosition: .CenteredHorizontally)
    }
  }

  /** updateTracks */
  func updateTracks(notification: NSNotification) {
    guard let cellCount = collectionView?.numberOfItemsInSection(Section.Instruments.rawValue),
              trackCount = Sequencer.sequence?.instrumentTracks.count where cellCount != trackCount else { return }

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
    guard let sequence = Sequencer.sequence,
              size = (collectionViewLayout as? MixerLayout)?.itemSize else { return .zero }
    let itemCount = sequence.instrumentTracks.count + 2
    return CGSize(width: CGFloat(Int(size.width) * itemCount), height: size.height)
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
    return section == Section.Instruments.rawValue ? Sequencer.sequence?.instrumentTracks.count ?? 0 : 1
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
        (cell as? TrackCell)?.track = Sequencer.sequence?.instrumentTracks[indexPath.item]
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
    Sequencer.sequence?.currentTrack = Sequencer.sequence?.instrumentTracks[indexPath.item]
  }

}
