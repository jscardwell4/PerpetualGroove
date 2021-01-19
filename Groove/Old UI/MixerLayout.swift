//
//  MixerLayout.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/10/21.
//  Copyright (c) 2021 Moondeer Studios. All rights reserved.
//
import UIKit
import MoonDev

// MARK: - MixerLayout

/// Custom layout for `MixerContainer.ViewController`.
@available(iOS 14.0, *)
public final class MixerLayout: UICollectionViewLayout
{
  public typealias Attributes = UICollectionViewLayoutAttributes

  /// The size of an item in the collection.
  internal let itemSize = CGSize(width: 100, height: 575)

  private let magnifyingTransform = CGAffineTransform(a: 1.1, b: 0, c: 0,
                                                      d: 1.1, tx: 0, ty: 30)

  /// The index path for the cell with a non-identity transform.
  public var magnifiedItem: IndexPath?
  {
    didSet
    {
      guard magnifiedItem != oldValue else { return }

      switch (oldValue, magnifiedItem)
      {
        case (nil, let newIndexPath?):
          attributesCache[newIndexPath]?.transform = magnifyingTransform

        case let (oldIndexPath?, newIndexPath?):
          attributesCache[oldIndexPath]?.transform = .identity
          attributesCache[newIndexPath]?.transform = magnifyingTransform

        case (let oldIndexPath?, nil):
          attributesCache[oldIndexPath]?.transform = .identity

        case (nil, nil):
          break
      }
    }
  }

  /// The cache of cell attributes.
  private var attributesCache = OrderedDictionary<IndexPath, Attributes>()

  /// Overridden to generate attributes for the current set of items.
  override public func prepare()
  {
    var tuples: [(key: IndexPath, value: Attributes)] = []

    for indexPath in Section.sections.map({ $0.indexPaths }).joined()
    {
      guard let attributes = layoutAttributesForItem(at: indexPath) else { continue }
      tuples.append((key: indexPath, value: attributes))
    }

    attributesCache = OrderedDictionary<IndexPath, Attributes>(tuples)
  }

  /// Returns all cached attributes with frames that intersect `rect`.
  override public func layoutAttributesForElements(in rect: CGRect) -> [Attributes]?
  {
    let result = Array(attributesCache.values.filter { $0.frame.intersects(rect) })
    return result.isEmpty ? nil : result
  }

  /// Returns attributes with an appropriate frame for `indexPath`.
  /// Also sets a non-identity transform when `indexPath == magnifiedItem`.
  override public func layoutAttributesForItem(at indexPath: IndexPath) -> Attributes?
  {
    guard let section = Section(indexPath) else { return nil }

    let attributes = Attributes(forCellWith: indexPath)

    let origin: CGPoint

    switch section
    {
      case .master: origin = .zero
      case .tracks: origin = CGPoint(x: itemSize
                                      .width * CGFloat(indexPath.item + 1),
                                     y: 0)
      case .add: origin = CGPoint(
        x: itemSize.width * (CGFloat(Section.tracks.itemCount) + 1),
        y: 0
      )
    }

    attributes.frame = CGRect(origin: origin, size: itemSize)
    attributes.transform = magnifiedItem == indexPath
      ? magnifyingTransform
      : .identity

    return attributes
  }

  /// Overridden to keep track of the magnified cell during track reordering.
  override public func prepare(
    forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]
  )
  {
    defer { super.prepare(forCollectionViewUpdates: updateItems) }

    // Check that the magnified item's location has changed.
    guard let updateItem = updateItems.first,
          let beforePath = updateItem.indexPathBeforeUpdate,
          let afterPath = updateItem.indexPathAfterUpdate,
          magnifiedItem == beforePath, beforePath != afterPath
    else
    {
      return
    }

    magnifiedItem = afterPath
  }

  /// Size derived from the max x and y values from the frame of
  /// the right-most cell attributes.
  override public var collectionViewContentSize: CGSize
  {
    guard let lastItemFrame = attributesCache.last?.value.frame else { return .zero }
    return CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)
  }
}

@available(iOS 14.0, *)
extension MixerLayout
{
  /// Type for specifying a section in the collection.
  @available(iOS 14.0, *)
  public enum Section: Int
  {
    /// Single-cell section providing an interface for master volume and pan control.
    case master

    /// Multi-cell section with controls for each track in a sequence.
    case tracks

    /// Single-cell section providing a control for creating a new track in a sequence.
    case add

    /// Initialize with section information in an index path.
    public init?(_ indexPath: IndexPath)
    {
      guard let section = Section(rawValue: indexPath.section)
      else
      {
        logw("Invalid index path: \(indexPath)")
        return nil
      }
      self = section
    }

    /// Returns an index path for `item` in the section disregarding whether
    /// `item` actually exists.
    public subscript(item: Int) -> IndexPath { IndexPath(item: item, section: rawValue) }

    /// Returns whether an item exists in the section as specified by `indexPath`.
    public func contains(_ indexPath: IndexPath) -> Bool
    {
      indexPath.section == rawValue && (0 ..< itemCount).contains(indexPath.item)
    }

    /// Returns the number of cells reported by `collectionView` for the section.
    public func cellCount(in collectionView: UICollectionView) -> Int
    {
      collectionView.numberOfItems(inSection: rawValue)
    }

    /// Returns the number of items for the section.
    public var itemCount: Int
    {
      self == .tracks ? sequence?.instrumentTracks.count ?? 0 : 1
    }

    /// An array of all the index paths that are valid for the section.
    public var indexPaths: [IndexPath]
    {
      (0 ..< itemCount).map { IndexPath(item: $0, section: rawValue) }
    }

    /// An array of all possible `Section` values.
    public static var sections: [Section] { [.master, .tracks, .add] }

    /// Subscript access for `Section.sections`.
    public static subscript(section: Int) -> Section { sections[section] }

    /// Total number of items across all three sections.
    public static var totalItemCount: Int { Section.tracks.itemCount &+ 2 }

    /// The cell identifier for cells in the section.
    public var reuseIdentifier: String
    {
      switch self
      {
        case .master: return "MasterCell"
        case .add: return "AddTrackCell"
        case .tracks: return "TrackCell"
      }
    }
  }
}
