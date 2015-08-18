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
  }

  /** updateViewConstraints */
  override func updateViewConstraints() {
    super.updateViewConstraints()
    view.removeAllConstraints()
    let trackCount = Mixer.tracks.count
    view.constrain(view.width => Float(64 * trackCount + 10 * (trackCount - 1)), view.height => 300)
    view.constrain(𝗩|collectionView!|𝗩, 𝗛|collectionView!|𝗛)
  }

  func updateTracks() {
    guard let collectionView = collectionView else { return }
    let itemCount = collectionView.numberOfItemsInSection(0)
    let trackCount = Mixer.tracks.count
    if itemCount != trackCount {
      view.setNeedsUpdateConstraints()
      view.setNeedsLayout()
      view.layoutIfNeeded()
      collectionView.reloadData()
    }
  }

  // MARK: UICollectionViewDataSource

  /**
  numberOfSectionsInCollectionView:

  - parameter collectionView: UICollectionView

  - returns: Int
  */
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 1 }


  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return Mixer.tracks.count
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
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TrackCell.Identifier,
                                                        forIndexPath: indexPath) as! TrackCell
    cell.track = Mixer.tracks[AudioUnitElement(indexPath.item)]
    return cell
  }

}
