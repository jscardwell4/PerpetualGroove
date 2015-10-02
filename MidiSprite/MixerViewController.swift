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

  /** addTrack */
  @IBAction func addTrack() {
    logDebug()
    guard let sequence = Sequencer.sequence else { logWarning("Cannot add a track without a sequence"); return }
    let instrument = Sequencer.instrumentWithCurrentSettings()
    do {
      let track =  try sequence.newTrackWithInstrument(instrument)
      sequence.currentTrack = track
    } catch {
      logError(error, message: "Failed to add new track")
    }

  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    collectionView?.translatesAutoresizingMaskIntoConstraints = false

    guard notificationReceptionist == nil else { return }

    let busesDidChange: (NSNotification) -> Void = { [unowned self] _ in self.updateTracks() }
    let queue = NSOperationQueue.mainQueue()
    let callback: (AnyObject?, NSOperationQueue?, (NSNotification) -> Void) = (MIDISequence.self, queue, busesDidChange)
    let callbacks: [NotificationReceptionist.Notification:NotificationReceptionist.Callback] = [
      MIDISequence.Notification.DidAddTrack.rawValue: callback,
      MIDISequence.Notification.DidRemoveTrack.rawValue: callback
    ]


    notificationReceptionist = NotificationReceptionist(callbacks: callbacks)
  }

  private let constraintID = Identifier("MixerViewController", "Internal")

  /** updateViewConstraints */
  override func updateViewConstraints() {
    guard let sequence = Sequencer.sequence else { super.updateViewConstraints(); return }
    guard view.constraintsWithIdentifier(constraintID).count == 0 else { return }
    let itemCount = sequence.instrumentTracks.count + 1
    let cellSize = (collectionView!.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
    let cellWidth = Int(cellSize.width)
    let cellSpacing = Int((collectionView!.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing)
    let viewWidth = Float(cellWidth * itemCount + cellSpacing * (itemCount - 1))
    let viewHeight = Float(cellSize.height)
    view.constrain([view.width => viewWidth -!> 750, view.height => viewHeight -!> 750] --> constraintID)
    view.constrain([𝗩|collectionView!|𝗩, 𝗛|collectionView!|𝗛] --> constraintID)
    super.updateViewConstraints()
  }

  /** updateTracks */
  func updateTracks() {
    guard let collectionView = collectionView, sequence = Sequencer.sequence else { return }
    let itemCount = collectionView.numberOfItemsInSection(1)
    let busCount = sequence.instrumentTracks.count
    if itemCount != busCount {
      view.removeConstraints(view.constraintsWithIdentifier(constraintID))
      view.setNeedsUpdateConstraints()
      collectionView.reloadData()
    }
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
    return section == 1 ? Sequencer.sequence?.instrumentTracks.count ?? 0 : 1
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
    guard let cell = cell as? AddTrackCell else { return }
    delayedDispatchToMain(0) {
      cell.generateBackdrop()
    }
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
      case 0:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(MasterCell.Identifier, forIndexPath: indexPath)
        (cell as? MasterCell)?.refresh()
      case 2:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(AddTrackCell.Identifier, forIndexPath: indexPath)
      default:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(TrackCell.Identifier, forIndexPath: indexPath)
        (cell as? TrackCell)?.track = Sequencer.sequence?.instrumentTracks[indexPath.item]
    }
    
    return cell
  }

}
