//
//  MixerLayout.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/10/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class MixerLayout: UICollectionViewLayout {

  let itemSize = CGSize(width: 100, height: 575)

  static private let SecondaryControllerKind = "SecondaryController"
  static private let secondaryControllerIndexPath = NSIndexPath(forItem: 0, inSection: 3)

  var presentingSecondaryController: Bool = false {
    didSet {
      guard presentingSecondaryController != oldValue else { return }
      invalidateLayout()
    }
  }

  private typealias AttributesIndex = OrderedDictionary<NSIndexPath, UICollectionViewLayoutAttributes>
  private var storedAttributes: AttributesIndex = [:]

  /** prepareLayout */
  override func prepareLayout() {
    super.prepareLayout()

    guard let collectionView = collectionView else { storedAttributes = [:]; return }

    storedAttributes = AttributesIndex(
      (0 ..< collectionView.numberOfSections()).flatMap {
        s in (0 ..< collectionView.numberOfItemsInSection(s)).map { r in NSIndexPath(forRow: r, inSection: s) }
      } .map { ($0, self.layoutAttributesForItemAtIndexPath($0)!) }
    )
  }

  /**
  layoutAttributesForElementsInRect:

  - parameter rect: CGRect

  - returns: [UICollectionViewLayoutAttributes]?
  */
  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var result = Array(storedAttributes.values.filter({ $0.frame.intersects(rect) }))
    if presentingSecondaryController,
      let attributes = layoutAttributesForSupplementaryViewOfKind(MixerLayout.SecondaryControllerKind,
                                                      atIndexPath: MixerLayout.secondaryControllerIndexPath)
    {
      result.append(attributes)
    }
    return result
  }

  /**
  layoutAttributesForItemAtIndexPath:

  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewLayoutAttributes!
  */
  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    guard let collectionView = collectionView else { return nil }

    let attributesClass = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forCellWithIndexPath: indexPath)

    let origin: CGPoint
    switch indexPath.section {
      case 0:
        origin = .zero
      case 1:
        origin = CGPoint(x: itemSize.width * CGFloat(indexPath.item + 1), y: 0)
      case 2: fallthrough
      default:
        origin = CGPoint(x: itemSize.width * CGFloat(collectionView.numberOfItemsInSection(1) + 1), y: 0)
    }
    attributes.frame = CGRect(origin: origin, size: itemSize)

    return attributes
  }

  /**
   layoutAttributesForSupplementaryViewOfKind:atIndexPath:

   - parameter elementKind: String
   - parameter indexPath: NSIndexPath

    - returns: UICollectionViewLayoutAttributes?
  */
  override func layoutAttributesForSupplementaryViewOfKind(elementKind: String,
    atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
  {
    guard let collectionView = collectionView else { return nil }

    let attributesClass = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
    attributes.frame = collectionView.bounds
    attributes.zIndex = 100
    return attributes
  }

  /**
  collectionViewContentSize

  - returns: CGSize
  */
  override func collectionViewContentSize() -> CGSize {
    let w = storedAttributes.values.reduce(0, combine: {max($0, $1.frame.maxX)})
    let h = storedAttributes.values.reduce(0, combine: {max($0, $1.frame.maxY)})
    return CGSize(width: w, height: h)
  }

}