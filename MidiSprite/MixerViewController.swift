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

  private var notificationReceptionist: NotificationReceptionist?

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
    //logDebug(dumpSelection())
  }


//  var movingCell: TrackCell? { didSet { logDebug("movingCell = \(movingCell)") } }

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
        collectionView.moveItemAtIndexPath(indexPath, toIndexPath: NSIndexPath(forItem: indexPath.item - 1, inSection: 1))
      case let (indexPath?, .Right) where indexPath.section == 1 && indexPath.item < collectionView.numberOfItemsInSection(1) - 1:
        collectionView.moveItemAtIndexPath(indexPath, toIndexPath: NSIndexPath(forItem: indexPath.item + 1, inSection: 1))
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

    guard notificationReceptionist == nil else { return }
    notificationReceptionist = generateNotificationReceptionist()
  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    if let idx = Sequencer.sequence?.currentTrackIndex { currentTrackIndexPath = NSIndexPath(forItem: idx, inSection: 1) }
  }

  /**
  generateNotificationReceptionist

  - returns: NotificationReceptionist
  */
  private func generateNotificationReceptionist() -> NotificationReceptionist {
    let receptionist = NotificationReceptionist()
    let queue = NSOperationQueue.mainQueue()

    receptionist.observe(MIDIDocumentManager.Notification.DidChangeDocument,
                    from: MIDIDocumentManager.self,
                   queue: queue,
                callback: documentChanged)

    guard let sequence = Sequencer.sequence else { return receptionist }

    receptionist.observe(MIDISequence.Notification.DidChangeTrack, from: sequence, queue: queue, callback: trackChanged)
    receptionist.observe(MIDISequence.Notification.DidAddTrack,    from: sequence, queue: queue, callback: updateTracks)
    receptionist.observe(MIDISequence.Notification.DidRemoveTrack, from: sequence, queue: queue, callback: updateTracks)

    return receptionist
  }

  /**
  currentDocumentDidChange:

  - parameter notification: NSNotification
  */
  private func documentChanged(notification: NSNotification) {
    notificationReceptionist = generateNotificationReceptionist()
    collectionView?.reloadData()
  }

  private var currentTrackIndexPath: NSIndexPath? {
    didSet {
      guard currentTrackIndexPath != oldValue else { return }

      guard let sequence = Sequencer.sequence, collectionView = collectionView else { return }

      switch (currentTrackIndexPath, sequence.currentTrack) {

        case let (indexPath?, currentTrack?) where sequence.instrumentTracks[indexPath.item] != currentTrack:
          sequence.currentTrack = sequence.instrumentTracks[indexPath.item]
          if let selectedPaths = collectionView.indexPathsForSelectedItems() where selectedPaths ∌ indexPath {
            collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .CenteredHorizontally)
          }

        case (nil, .Some):
          sequence.currentTrack = nil
          if let selectedPath = collectionView.indexPathsForSelectedItems()?.first {
            collectionView.deselectItemAtIndexPath(selectedPath, animated: true)
          }
        default:
          break
      }
      //logDebug(dumpSelection())
    }
  }

  /**
  trackChanged:

  - parameter notification: NSNotification
  */
  private func trackChanged(notification: NSNotification) {
//    if let oldTrack = notification.userInfo?[MIDISequence.Notification.Key.OldTrack.rawValue] as? InstrumentTrack,
//           currentTrackIndexPath = currentTrackIndexPath,
//           cell = collectionView?.cellForItemAtIndexPath(currentTrackIndexPath) as? TrackCell
//             where cell.track == oldTrack
//    {
//      collectionView?.deselectItemAtIndexPath(currentTrackIndexPath, animated: true)
//    }

    if let newTrack = notification.userInfo?[MIDISequence.Notification.Key.Track.rawValue] as? InstrumentTrack,
      idx = Sequencer.sequence?.instrumentTracks.indexOf(newTrack),
      cell = collectionView?.cellForItemAtIndexPath(NSIndexPath(forItem: idx,
                                                                inSection: Section.Instruments.rawValue))
      where (cell as? TrackCell)?.track == newTrack && !cell.selected
    {
      currentTrackIndexPath = NSIndexPath(forItem: idx, inSection: Section.Instruments.rawValue)
      collectionView?.selectItemAtIndexPath(currentTrackIndexPath,
                                   animated: true,
                             scrollPosition: .CenteredHorizontally)
      //logDebug(dumpSelection())
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
  collectionView:willDisplayCell:forItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter cell: UICollectionViewCell
  - parameter indexPath: NSIndexPath
  */
//  override func collectionView(collectionView: UICollectionView,
//               willDisplayCell cell: UICollectionViewCell,
//            forItemAtIndexPath indexPath: NSIndexPath)
//  {
//    guard let sequence = Sequencer.sequence, currentTrack = sequence.currentTrack, cell = cell as? TrackCell else { return }
//    cell.selected = cell.track == currentTrack
//  }

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
  override func collectionView(collectionView: UICollectionView,
   shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
  {
    //logDebug(dumpSelection())
    return indexPath.section == 1
  }

  /**
  collectionView:didSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    //logDebug(dumpSelection())
    currentTrackIndexPath = indexPath
  }

  /**
  collectionView:didDeselectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
    //logDebug(dumpSelection())
    if currentTrackIndexPath == indexPath { currentTrackIndexPath = nil }
  }
  
}

// MARK: - Debugging

extension MixerViewController {

  /** dumpSelection */
  func dumpSelection() -> String {
    var result = "currentTrackIndexPath: " + (currentTrackIndexPath == nil ? "nil" : "\(currentTrackIndexPath!)") + "\n"
    guard let selection = collectionView?.indexPathsForSelectedItems() else { result += "selection: nil"; return result }
    result += "selection: [\n\t" + ",\n\t".join(selection.map {"\($0)"}) + "\n]"
    return result
  }

}
