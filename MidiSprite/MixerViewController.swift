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

class MixerViewController: UICollectionViewController {

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()
    view.translatesAutoresizingMaskIntoConstraints = false
    collectionView?.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = nil
    collectionView?.backgroundColor = nil

    NSNotificationCenter.defaultCenter().addObserverForName(Mixer.Notification.NotificationName.DidAddTrack.rawValue,
                                                     object: nil,
                                                      queue: NSOperationQueue.mainQueue()) {
                                                        [weak self] _ in
                                                        self?.updateTracks()
    }
    NSNotificationCenter.defaultCenter().addObserverForName(Mixer.Notification.NotificationName.DidRemoveTrack.rawValue,
                                                     object: nil,
                                                      queue: NSOperationQueue.mainQueue()) {
                                                        [weak self] _ in
                                                        self?.updateTracks()
    }
  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()
    view.removeAllConstraints()
    let itemCount = Mixer.instruments.count + 1
    view.constrain(view.width => Float(74 * itemCount + 10 * (itemCount - 1)), view.height => 300)
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

  deinit { NSNotificationCenter.defaultCenter().removeObserver(self) }

  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return section == 0 ? 1 : Mixer.instruments.count
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
        (cell as? TrackCell)?.track = TrackManager.tracks[indexPath.item]
    }
    
    return cell
  }

}
