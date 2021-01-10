//
//  AddTrackCell.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright (c) 2021 Moondeer Studios. All rights reserved.
//
import UIKit
import MoonKit

// MARK: - AddTrackCell

/// Simple subclass of `UICollectionViewCell` that displays a button over a
/// background for triggering new track creation.
public final class AddTrackCell: UICollectionViewCell
{
  /// Button whose action invokes `MixerContainer.ViewController.addTrack`.
  @IBOutlet public var addTrackButton: ImageButtonView!

  /// Overridden to ensure `addTrackButton` state has been reset.
  override public func prepareForReuse()
  {
    super.prepareForReuse()
    addTrackButton.isSelected = false
    addTrackButton.isHighlighted = false
  }
}

