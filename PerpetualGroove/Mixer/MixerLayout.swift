//
//  MixerLayout.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/10/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

// TODO: Review file
import UIKit

final class MixerLayout: UICollectionViewLayout {

  static let itemSize = CGSize(width: 100, height: 575)
  static let magnifiedItemSize = CGSize(width: 104.347826086957, height: 600)

  static private let SecondaryControllerKind = "SecondaryController"
  static private let secondaryControllerIndexPath = IndexPath(item: 0, section: 3)

  @IBOutlet weak var delegate: MixerViewController!

  private var previouslyMagnifiedItem: IndexPath?

  var magnifiedItem: IndexPath? {
    didSet {
      guard magnifiedItem != oldValue else { return }
      invalidateLayout()
    }
  }


  var presentingSecondaryController: Bool = false {
    didSet {
      guard presentingSecondaryController != oldValue else { return }
      invalidateLayout()
    }
  }

  private typealias AttributesIndex = OrderedDictionary<IndexPath, UICollectionViewLayoutAttributes>
  private var storedAttributes: AttributesIndex = [:]

  override func prepare() {
    super.prepare()

    guard let collectionView = collectionView else { storedAttributes = [:]; return }

    storedAttributes.removeAll(keepingCapacity: true)

    for section in 0 ..< collectionView.numberOfSections {
      for item in 0 ..< collectionView.numberOfItems(inSection: section) {
        let indexPath = IndexPath(item: item, section: section)
        let layoutAttributes = layoutAttributesForItem(at: indexPath)
        storedAttributes[indexPath] = layoutAttributes
      }
    }

  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var result = Array(storedAttributes.values.filter({ $0.frame.intersects(rect) }))
    if presentingSecondaryController,
      let attributes = layoutAttributesForSupplementaryView(ofKind: MixerLayout.SecondaryControllerKind,
                                                            at: MixerLayout.secondaryControllerIndexPath)
    {
      result.append(attributes)
    }
    return result
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard collectionView != nil else { return nil }
    return attributesForItem(at: indexPath, magnified: magnifiedItem == indexPath)
  }

  private func attributesForItem(at indexPath: IndexPath,
                                 magnified: Bool = false) -> UICollectionViewLayoutAttributes
  {
    let attributesClass = type(of: self).layoutAttributesClass as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forCellWith: indexPath as IndexPath)

    let origin: CGPoint

    switch indexPath.section {
      case 0:
        origin = .zero
      case 1:
        origin = CGPoint(x: MixerLayout.itemSize.width * CGFloat(indexPath.item + 1), y: 0)
      case 2: fallthrough
      default:
        origin = CGPoint(x: MixerLayout.itemSize.width * CGFloat((collectionView?.numberOfItems(inSection: 1) ?? 0 ) + 1), y: 0)
    }
    attributes.frame = CGRect(origin: origin, size: MixerLayout.itemSize)
    if magnified {
      attributes.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                              .translatedBy(x: 0, y: half(MixerLayout.itemSize.height * 1.1 - MixerLayout.itemSize.height))
    }
    return attributes
  }

  override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
    defer { super.prepare(forCollectionViewUpdates: updateItems) }
    guard updateItems.count == 1,
      let updateItem = updateItems.first,
          let beforePath = updateItem.indexPathBeforeUpdate , magnifiedItem == beforePath,
      let afterPath = updateItem.indexPathAfterUpdate else { return }
    previouslyMagnifiedItem = beforePath
    magnifiedItem = afterPath
  }

  override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                     at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
  {
    guard let collectionView = collectionView else { return nil }

    let attributesClass = type(of: self).layoutAttributesClass as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forSupplementaryViewOfKind: elementKind, with: indexPath)
    attributes.frame = collectionView.bounds
    attributes.zIndex = 100
    return attributes
  }

  override var collectionViewContentSize: CGSize {
    let w = storedAttributes.values.reduce(0, {max($0, $1.frame.maxX)})
    let h = storedAttributes.values.reduce(0, {max($0, $1.frame.maxY)})
    return CGSize(width: w, height: h)
  }

}
