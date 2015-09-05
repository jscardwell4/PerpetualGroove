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

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    collectionView?.translatesAutoresizingMaskIntoConstraints = false

    guard notificationReceptionist == nil else { return }

    let busesDidChange: (NSNotification) -> Void = { [unowned self] _ in self.updateTracks() }
    let queue = NSOperationQueue.mainQueue()
    let callback: (AnyObject?, NSOperationQueue?, (NSNotification) -> Void) = (Mixer.self, queue, busesDidChange)
    let callbacks: [NotificationReceptionist.Notification:NotificationReceptionist.Callback] = [
      Mixer.Notification.Name.DidAddBus.rawValue: callback,
      Mixer.Notification.Name.DidRemoveBus.rawValue: callback
    ]

    notificationReceptionist = NotificationReceptionist(callbacks: callbacks)

  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()
    view.removeAllConstraints()
    let itemCount = Mixer.instruments.count + 1
    view.constrain(view.width => Float(100 * itemCount + 10 * (itemCount - 1)), view.height => 400)
    view.constrain(𝗩|collectionView!|𝗩, 𝗛|collectionView!|𝗛)
  }

  func updateTracks() {
    guard let collectionView = collectionView else { return }
    let itemCount = collectionView.numberOfItemsInSection(1)
    let busCount = Mixer.instruments.count
    if itemCount != busCount {
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
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 2 }

  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return section == 0 ? 1 : Sequencer.sequence.tracks.count
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
      default:
        cell = collectionView.dequeueReusableCellWithReuseIdentifier(TrackCell.Identifier, forIndexPath: indexPath)
        (cell as? TrackCell)?.track = Sequencer.sequence.tracks[indexPath.item]
    }
    
    return cell
  }

}
